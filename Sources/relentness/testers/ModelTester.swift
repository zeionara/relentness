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
    // public func runSingleTest(config: Config, workerIndex: Int?, seed: Int?) async throws -> MetricTree

    func runCvSplitTest(config: Config, cvSplitIndex: Int, seeds: [Int]?, delay: Double?) async throws -> [MetricTree]  // medium-level test
    // public func runSingleTest(config: Config, seeds: [Int]?, delay: Double?) async throws -> [MetricTree]

    func run(config: Config, seeds: [Int]?, delay: Double?) async throws -> [[MetricTree]]  // high-level test
}

public extension ModelTester {
    // init(
    //     model: ModelType, configRoot: URL, env: String, gpu: Bool = true, differentGpus: Bool = true, terminationDelay: Double? = nil, nWorkers: Int? = nil, logLevel: Logger.Level = .info
    // ) {
    //     self.init(
    //         model: model,
    //         configRoot: configRoot,
    //         env: env,
    //         gpu: gpu,
    //         differentGpus: differentGpus,
    //         terminationDelay: terminationDelay,
    //         nWorkers: nWorkers,
    //         logger: Logger(level: logLevel, label: "grapex-tester")
    //     )

    //     logger = Logger(level: logLevel, label: "grapex-tester")

    //     self.model = model

    //     self.gpu = gpu
    //     self.differentGpus = differentGpus

    //     self.terminationDelay = terminationDelay

    //     self.configRoot = configRoot
    //     self.env = env

    //     self.nWorkers = nWorkers
    // }

    func runSeedTest(config: Config, cvSplitIndex: Int, workerIndex: Int? = nil, seed: Int? = nil) async throws -> MetricTree {
        let configPath = configRoot.appendingPathComponent(config.name.yaml)
        try config.write(to: configPath, as: .yaml, userInfo: [PLATFORM_CODING_USER_INFO_KEY: Self.platform])

        // Configure args

        // var args = ["run", "main.exs", "\(configPath.path)", "-c"]
        var args = initialArgs // ["run", "main.exs", "\(configPath.path)", "-c"]

        if let seed = seed {
            args.append(
                contentsOf: ["\(configPath.path)", "-c", "-s", String(describing: seed)]
            )
        }

        // Configure env

        var env = initialEnv

        env["TF_CPP_MIN_LOG_LEVEL"] = "3"

        // let envVars = ["TF_CPP_MIN_LOG_LEVEL": "3", "LC_ALL": "en_US.UTF-8"]

        // if gpu {
        //     args.append(
        //         contentsOf: ["-c", "xla"]
        //     )
        //     if let unwrappedWorkerIndex = workerIndex, differentGpus {
        //         envVars["CUDA_VISIBLE_DEVICES"] = String(describing: unwrappedWorkerIndex)
        //     }
        // }

        logger.debug("Running command '\(args.joined(separator: " "))'")

        do {
            let metrics = try await measureExecutionTime {
                try await runSubprocessAndGetOutput(
                    // path: "/home/\(USER)/\(env)/grapex",
                    // path: URL(fileURLWithPath: "/home/\(USER)/\(env)"),
                    path: path,
                    // executable: URL(fileURLWithPath: "/home/\(USER)/.asdf/shims/mix"),
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

            // print(try seededMetrics.avg()?.describe())

            return seededMetrics
            // return result
        }
    }
}
