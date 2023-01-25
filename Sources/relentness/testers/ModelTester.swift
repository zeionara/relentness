import Foundation
import Logging

typealias Metrics = MeagerMetricSet

public protocol ModelTester {
    associatedtype ModelType

    static var platform: Platform { get }

    var model: ModelType { get }

    var gpu: Bool { get }
    var differentGpus: Bool { get }

    var terminationDelay: Double? { get }

    var configRoot: URL { get }
    var env: String { get }

    var nWorkers: Int? { get }

    var logger: Logger { get }

    // Platform-specific

    var initialArgs: [String] { get }
    var initialEnv: [String: String] { get }

    var path: URL { get }
    var executable: URL { get }

    init(model: ModelType, configRoot: URL, env: String, gpu: Bool, differentGpus: Bool, terminationDelay: Double?, nWorkers: Int?, logLevel: Logger.Level)

    func runSeedTest(config: Config, cvSplitIndex: Int, workerIndex: Int?, seed: Int?) async throws -> MetricTree  // low-level test

    func runCvSplitTest(config: Config, cvSplitIndex: Int, seeds: [Int]?, delay: Double?) async throws -> [MetricTree]  // medium-level test

    func run(config: Config, seeds: [Int]?, delay: Double?) async throws -> [[MetricTree]]  // high-level test
}

public extension ModelTester {

    func runSeedTest(config: Config, cvSplitIndex: Int, workerIndex: Int? = nil, seed: Int? = nil) async throws -> MetricTree {
        let configPath = configRoot.appendingPathComponent(config.name.yaml)
        try config.write(to: configPath, as: .yaml, userInfo: [PLATFORM_CODING_USER_INFO_KEY: Self.platform])

        // Configure args

        var args = initialArgs

        args.append(contentsOf: ["\(configPath.path)", "-c"])

        if let seed = seed {
            args.append(
                contentsOf: ["-s", String(describing: seed)]
            )
        }

        // Configure env

        var env = initialEnv

        env["TF_CPP_MIN_LOG_LEVEL"] = "3"

        logger.debug("Running command '\(args.joined(separator: " "))'")

        do {
            let metrics = try await measureExecutionTime {
                try await runSubprocessAndGetOutput(
                    path: path,
                    executable: executable,
                    args: args,
                    env: env,
                    terminationDelay: terminationDelay
                )
            } handleExecutionTimeMeasurement: { output, nSeconds -> MetricTree in
                return MetricTree(
                    MetricNode(
                        output,
                        label: MetricNode.PART_LABEL
                    ),
                    MetricNode(
                        MetricTree(
                            Measurement(metric: .time, value: nSeconds)
                        ),
                        label: MetricNode.WHOLE_LABEL
                    )
                )
            }

            if let seed = seed {
                logger.debug("metrics for \(cvSplitIndex) split and seed = \(seed):\n\(metrics.describe())")
            } else {
                logger.debug("metrics for \(cvSplitIndex) split:\n\(metrics.describe())")
            }

            return metrics
        } catch let error {
           logger.error("Failed testing. Command which was used to start the process: \(args.joined(separator: " "))") 
           throw error 
        }
    }

    func runCvSplitTest(config: Config, cvSplitIndex: Int, seeds: [Int]? = nil, delay: Double? = nil) async throws -> [MetricTree] {
        if let seeds = seeds {
            if let nWorkers = nWorkers, nWorkers > 1 {
                return try await seeds.asyncMap(nWorkers: nWorkers, delay: delay) { seed, workerIndex in // TODO: Add support for total time (instead of computing sum, here max must me chosen)
                    return try await runSeedTest(
                        config: config,
                        cvSplitIndex: cvSplitIndex,
                        workerIndex: workerIndex,
                        seed: seed
                    ) 
                }
            } else {
               return try await seeds.map { seed in
                    return try await runSeedTest(
                        config: config,
                        cvSplitIndex: cvSplitIndex,
                        workerIndex: 0,
                        seed: seed
                    ) 
                }
            }
        }

        let result = try await runSeedTest(config: config, cvSplitIndex: cvSplitIndex, seed: nil)
        return [result]
    }

    func run(config: Config, seeds: [Int]? = nil, delay: Double? = nil) async throws -> [[MetricTree]] {
        return try await getNestedFolderNames(Path.corpora.appendingPathComponent(config.corpus.path)).map { cvSplitStringifiedIndex in // No parallelism on this level, cv splits are handled sequentially
            let seededMetrics = try await runCvSplitTest(
                config: config.appending(cvSplitIndex: cvSplitStringifiedIndex.asInt),
                cvSplitIndex: cvSplitStringifiedIndex.asInt,
                seeds: seeds,
                delay: delay
            )

            return seededMetrics
        }
    }
}
