import Foundation

public enum GrapexModel: String, Sendable {
    case transe
    case se
}

public struct GrapexTester: Tester {
    public typealias Metrics = MeagerMetricSet

    public let model: GrapexModel
    public let env: String
    public let corpus: String
    public let nWorkers: Int?

    public let remove: Bool
    public let gpu: Bool
    public let differentGpus: Bool

    public let terminationDelay: Double?

    public init(model: GrapexModel, env: String, corpus: String, nWorkers: Int? = nil, remove: Bool = false, gpu: Bool = true, differentGpus: Bool = true, terminationDelay: Double? = nil) {
        self.model = model
        self.env = env
        self.corpus = corpus
        self.nWorkers = nWorkers

        self.remove = remove
        self.gpu = gpu
        self.differentGpus = differentGpus
        self.terminationDelay = terminationDelay
    }

    public func runSingleTest(seed: Int? = nil) async throws -> Metrics {
        try await runSingleTest(seed: seed, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX)
    }

    public func runSingleTest(seed: Int? = nil, cvSplitIndex: Int, workerIndex: Int? = nil, hparams: HyperParamSet? = nil, usingValidationSubset: Bool = false) async throws -> Metrics {

        // Configure args

        var args = ["test", "\(corpus)/\(String(format: "%04i", cvSplitIndex))", "-m", model.rawValue, "-t"]
        if let unwrappedHparams = hparams {
            args.append(contentsOf: unwrappedHparams.grapexArgs)
        }

        if let unwrappedSeed = seed {
            args.append(
                contentsOf: ["-s", String(describing: unwrappedSeed)]
            )
        } else {
            args.append("-r")
        }

        if (remove && !args.contains("-r")) {
            args.append("-r")
        }

        if usingValidationSubset {
            args.append("--validate")
        }

        // Configure env

        var envVars = ["TF_CPP_MIN_LOG_LEVEL": "3", "LC_ALL": "en_US.UTF-8"]

        if gpu {
            args.append(
                contentsOf: ["-c", "xla"]
            )
            if let unwrappedWorkerIndex = workerIndex, differentGpus {
                envVars["CUDA_VISIBLE_DEVICES"] = String(describing: unwrappedWorkerIndex)
            }
        }

        // print("Running command '\(args.joined(separator: " "))'")

        do {
            return try await measureExecutionTime {
                try await runSubprocessAndGetOutput(
                    path: "/home/\(USER)/\(env)/grapex",
                    args: args,
                    env: envVars,
                    terminationDelay: terminationDelay
                )
            } handleExecutionTimeMeasurement: { output, nSeconds in
                return MeagerMetricSet(
                    output,
                    time: nSeconds
                )
            }
         } catch let error {
            print("Failed testing. Command which was used to start the process: \(args.joined(separator: " "))") 
            throw error 
         }
    }

    public func runSingleTest(seeds: [Int]? = nil, delay: Double?) async throws -> [Metrics] {
        try await runSingleTest(seeds: seeds, delay: delay, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX)
    }

    public func runSingleTest(seeds: [Int]? = nil, delay: Double? = nil, cvSplitIndex: Int, hparams: HyperParamSet? = nil, usingValidationSubset: Bool = false) async throws -> [Metrics] {
        if let unwrappedSeeds = seeds {
            if nWorkers == nil || nWorkers! > 1 {
                return try await unwrappedSeeds.asyncMap(nWorkers: nWorkers, delay: delay) { seed, workerIndex in // TODO: Add support for total time (instead of computing sum, here max must me chosen)
                    try await runSingleTest(
                       seed: seed,
                       cvSplitIndex: cvSplitIndex,
                       workerIndex: workerIndex,
                       hparams: hparams,
                       usingValidationSubset: usingValidationSubset
                    ) 
                }
            } else {
               return try await unwrappedSeeds.map { seed in
                    try await runSingleTest(
                       seed: seed,
                       cvSplitIndex: cvSplitIndex,
                       workerIndex: 0,
                       hparams: hparams,
                       usingValidationSubset: usingValidationSubset
                    ) 
                }
            }
        }

        let result: Metrics = try await runSingleTest(cvSplitIndex: cvSplitIndex)
        return [result]
    }

    public func run(seeds: [Int]? = nil, delay: Double? = nil, hparams: HyperParamSet? = nil) async throws -> [[Metrics]] {
        return try await getNestedFolderNames(corpusPath).map { cvSplitStringifiedIndex in // No parallelism on this level
            let result =  try await runSingleTest(
               seeds: seeds,
               delay: delay,
               cvSplitIndex: cvSplitStringifiedIndex.asInt,
               hparams: hparams
            ) 
            return result
        }
    }

    public var corpusPath: String {
        "./Assets/Corpora/\(corpus)"
    }
}

