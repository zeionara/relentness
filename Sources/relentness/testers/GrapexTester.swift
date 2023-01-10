import Foundation

public enum GrapexModel: String, Sendable {
    case transe
    case se
}

// public struct GrapexTester: Tester {
public struct GrapexTester {
    public typealias Metrics = MeagerMetricSet

    public let model: GrapexModel

    public let gpu: Bool
    public let differentGpus: Bool

    public let terminationDelay: Double?

    public let configRoot: URL
    public let env: String

    public let nWorkers: Int?

    public init(model: GrapexModel, configRoot: URL, env: String, gpu: Bool = true, differentGpus: Bool = true, terminationDelay: Double? = nil, nWorkers: Int? = nil) {
        self.model = model

        self.gpu = gpu
        self.differentGpus = differentGpus

        self.terminationDelay = terminationDelay

        self.configRoot = configRoot
        self.env = env

        self.nWorkers = nWorkers
    }

    // public func runSingleTest(config: Config, workerIndex: Int? = nil, seed: Int? = nil) async throws -> Metrics {
    public func runSingleTest(config: Config, workerIndex: Int? = nil, seed: Int? = nil) async throws -> Void {
        try await runSingleTest(config: config, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX, workerIndex: workerIndex, seed: seed)
    }

    // public func runSingleTest(config: Config, cvSplitIndex: Int, workerIndex: Int? = nil, seed: Int? = nil) async throws -> Metrics {
    public func runSingleTest(config: Config, cvSplitIndex: Int, workerIndex: Int? = nil, seed: Int? = nil) async throws -> Void {
        let configPath = configRoot.appendingPathComponent(config.name.yaml)
        try config.write(to: configPath, as: .yaml, userInfo: [PLATFORM_CODING_USER_INFO_KEY: Platform.grapex])

        // Configure args

        var args = ["run", "main.exs", "\(configPath.path)", "-c"]
        // var args = ["test", "\(corpus)/\(String(format: "%04i", cvSplitIndex))", "-m", model.rawValue, "-t"]
        // if let unwrappedHparams = hparams {
        //     // print("Unwrapped hparams")
        //     // print(unwrappedHparams)

        //     // print("Grapex args")
        //     // print(unwrappedHparams.grapexArgs)
        //     args.append(contentsOf: unwrappedHparams.grapexArgs)
        // }

        if let seed = seed {
            args.append(
                contentsOf: ["-s", String(describing: seed)]
            )
        }

        // if let unwrappedSeed = seed {
        //     args.append(
        //         contentsOf: ["-s", String(describing: unwrappedSeed)]
        //     )
        // } else {
        //     args.append("-r")
        // }

        // if (remove && !args.contains("-r")) {
        //     args.append("-r")
        // }

        // if usingValidationSubset {
        //     args.append("--validate")
        // }

        // Configure env

        let envVars = ["TF_CPP_MIN_LOG_LEVEL": "3", "LC_ALL": "en_US.UTF-8"]
        // let envVars = ["TF_CPP_MIN_LOG_LEVEL": "3"]
        // let envVars = [String: String]()

        // if gpu {
        //     args.append(
        //         contentsOf: ["-c", "xla"]
        //     )
        //     if let unwrappedWorkerIndex = workerIndex, differentGpus {
        //         envVars["CUDA_VISIBLE_DEVICES"] = String(describing: unwrappedWorkerIndex)
        //     }
        // }

        print("Running command '\(args.joined(separator: " "))'")

        do {
            let metrics = try await runSubprocessAndGetOutput(
                // path: "/home/\(USER)/\(env)/grapex",
                path: URL(fileURLWithPath: "/home/\(USER)/\(env)"),
                executable: URL(fileURLWithPath: "/home/\(USER)/.asdf/shims/mix"),
                args: args,
                env: envVars,
                terminationDelay: terminationDelay
            )
            print(metrics)
            // return try await measureExecutionTime {
            //     try await runSubprocessAndGetOutput(
            //         path: "/home/\(USER)/\(env)/grapex",
            //         args: args,
            //         env: envVars,
            //         terminationDelay: terminationDelay
            //     )
            // } handleExecutionTimeMeasurement: { output, nSeconds in
            //     return MeagerMetricSet(
            //         output,
            //         time: nSeconds
            //     )
            // }
        } catch let error {
           print("Failed testing. Command which was used to start the process: \(args.joined(separator: " "))") 
           throw error 
        }
    }

    // public func runSingleTest(config: Config, seeds: [Int]? = nil, delay: Double?) async throws -> [Metrics] {
    public func runSingleTest(config: Config, seeds: [Int]? = nil, delay: Double?) async throws {
        _ = try await runSingleTest(config: config, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX, seeds: seeds, delay: delay)
    }

    // public func runSingleTest(config: Config, cvSplitIndex: Int, seeds: [Int]? = nil, delay: Double? = nil) async throws -> [Metrics] {
    public func runSingleTest(config: Config, cvSplitIndex: Int, seeds: [Int]? = nil, delay: Double? = nil) async throws {
        if let seeds = seeds {
            if let nWorkers = nWorkers, nWorkers > 1 {
                _ = try await seeds.asyncMap(nWorkers: nWorkers, delay: delay) { seed, workerIndex in // TODO: Add support for total time (instead of computing sum, here max must me chosen)
                    try await runSingleTest(
                        config: config,
                        cvSplitIndex: cvSplitIndex,
                        workerIndex: workerIndex,
                        seed: seed
                    ) 
                }
            } else {
               _ = try await seeds.map { seed in
                    try await runSingleTest(
                        config: config,
                        cvSplitIndex: cvSplitIndex,
                        workerIndex: 0,
                        seed: seed
                    ) 
                }
            }
        }

        // let result: Metrics = try await runSingleTest(cvSplitIndex: cvSplitIndex)
        // return [result]
    }

    // public func run(seeds: [Int]? = nil, delay: Double? = nil, hparams: HyperParamSet? = nil) async throws -> [[Metrics]] {
    // public func run(config: Config, seeds: [Int]? = nil, delay: Double? = nil) async throws -> [[Metrics]] {
    public func run(config: Config, seeds: [Int]? = nil, delay: Double? = nil) async throws {
        _ = try await getNestedFolderNames(Path.corpora.appendingPathComponent(config.corpus.path)).map { cvSplitStringifiedIndex in // No parallelism on this level, cv splits are handled sequentially
            _ =  try await runSingleTest(
                config: config.appending(cvSplitIndex: cvSplitStringifiedIndex.asInt),
                cvSplitIndex: cvSplitStringifiedIndex.asInt,
                seeds: seeds,
                delay: delay
            ) 
            // return result
        }
    }

    // public var corpusPath: String {
    //     "./Assets/Corpora/\(corpus)"
    // }
}
