import Foundation

public protocol Tester: Sendable {
    associatedtype Metrics: MetricSet

    func runSingleTest(seed: Int?) async throws -> Metrics
    func runSingleTest(seeds: [Int]?, delay: Double?) async throws -> [Metrics]
    func run(seeds: [Int]?, delay: Double?, hparams: HyperParamSet?) async throws -> [[Metrics]]
}

public enum OpenKeModel: String, Sendable {
    case transe
    case complex
}

public let DEFAULT_CV_SPLIT_INDEX: Int = 0
public let USER = ProcessInfo.processInfo.environment["USER"]!

public struct OpenKeTester: Tester {
    public typealias Metrics = MeagerMetricSet

    public let model: OpenKeModel
    public let env: String
    public let corpus: String
    public let nWorkers: Int?

    public let remove: Bool
    public let gpu: Bool
    public let differentGpus: Bool

    public let terminationDelay: Double?

    public init(model: OpenKeModel, env: String, corpus: String, nWorkers: Int? = nil, remove: Bool = false, gpu: Bool = true, differentGpus: Bool = true, terminationDelay: Double? = nil) {
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

        var args = ["-m", "relentness", "test", "\(corpusPath)/\(String(format: "%04i", cvSplitIndex))/", "-m", model.rawValue, "-t"]
        if let unwrappedHparams = hparams {
            args.append(contentsOf: unwrappedHparams.openKeArgs)
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
            args.append("-val")
        }

        // Configure env

        var envVars = ["TF_CPP_MIN_LOG_LEVEL": "3"]

        if !gpu {
            envVars["CUDA_VISIBLE_DEVICES"] = "-1"
        } else if let unwrappedWorkerIndex = workerIndex, differentGpus {
            envVars["CUDA_VISIBLE_DEVICES"] = String(describing: unwrappedWorkerIndex)
        }

        return try await measureExecutionTime {
            try await runSubprocessAndGetOutput(
                path: "/home/\(USER)/anaconda3/envs/\(env)/bin/python",
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

public extension Array {
    func map<Type>(closure: (Element) async throws -> Type) async throws -> [Type] {
        var result = [Type]()

        for item in self {
            result.append(
                try await closure(item)
            )
        }

        return result
    }
}

