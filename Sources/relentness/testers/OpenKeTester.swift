import Foundation

public protocol Tester: Sendable {
    associatedtype Metrics: MetricSet

    func runSingleTest(seed: Int?) async throws -> Metrics
    func runSingleTest(seeds: [Int]?) async throws -> [Metrics]
    func run(seeds: [Int]?, hparams: HyperParamSet?) async throws -> [[Metrics]]
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

    public init(model: OpenKeModel, env: String, corpus: String, nWorkers: Int? = nil, remove: Bool = false, gpu: Bool = true, differentGpus: Bool = true) {
        self.model = model
        self.env = env
        self.corpus = corpus
        self.nWorkers = nWorkers

        self.remove = remove
        self.gpu = gpu
        self.differentGpus = differentGpus
    }

    public func runSingleTest(seed: Int? = nil) async throws -> Metrics {
        try await runSingleTest(seed: seed, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX)
    }

    public func runSingleTest(seed: Int? = nil, cvSplitIndex: Int, workerIndex: Int? = nil, hparams: HyperParamSet? = nil) async throws -> Metrics {
        // Configure args
        // print("Worker index = \(workerIndex)")

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

        // Configure env

        var envVars = ["TF_CPP_MIN_LOG_LEVEL": "3"]

        if !gpu {
            envVars["CUDA_VISIBLE_DEVICES"] = "-1"
        } else if let unwrappedWorkerIndex = workerIndex, differentGpus {
            envVars["CUDA_VISIBLE_DEVICES"] = String(describing: unwrappedWorkerIndex)
        }

        // print(envVars)

        // let output = 
        return try await measureExecutionTime {
            // print("/home/\(USER)/anaconda3/envs/\(env)/bin/python")
            // print("Run and get output")
            let output = try await runSubprocessAndGetOutput(
                path: "/home/\(USER)/anaconda3/envs/\(env)/bin/python",
                args: args,
                env: envVars
            )
            // print("Run and got output")
            return output
        } handleExecutionTimeMeasurement: { output, nSeconds in
            MeagerMetricSet(
                output,
                time: nSeconds
            )
        }
        // return MeagerMetricSet(output)
    }

    public func runSingleTest(seeds: [Int]? = nil) async throws -> [Metrics] {
        try await runSingleTest(seeds: seeds, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX)
    }

    public func runSingleTest(seeds: [Int]? = nil, cvSplitIndex: Int, hparams: HyperParamSet? = nil) async throws -> [Metrics] {
        if let unwrappedSeeds = seeds {
            if nWorkers == nil || nWorkers! > 1 {
                return try await unwrappedSeeds.asyncMap(nWorkers: nWorkers) { seed, workerIndex in // TODO: Add support for total time (instead of computing sum, here max must me chosen)
                    try await runSingleTest(
                       seed: seed,
                       cvSplitIndex: cvSplitIndex,
                       workerIndex: workerIndex,
                       hparams: hparams
                    ) 
                }
            } else {
               // print("Testing without parallelism...")
               return try await unwrappedSeeds.map { seed in
                    try await runSingleTest(
                       seed: seed,
                       cvSplitIndex: cvSplitIndex,
                       workerIndex: 0,
                       hparams: hparams
                    ) 
                }
            }
        }

        let result: Metrics = try await runSingleTest(cvSplitIndex: cvSplitIndex)
        return [result]
    }

    public func run(seeds: [Int]? = nil, hparams: HyperParamSet? = nil) async throws -> [[Metrics]] {
        // return try await getNestedFolderNames(corpusPath).asyncMap(nWorkers: 1) { cvSplitStringifiedIndex, _ in // No parallelism on this level
        return try await getNestedFolderNames(corpusPath).map { cvSplitStringifiedIndex in // No parallelism on this level
            // print("Running single test...")
            let result =  try await runSingleTest(
               seeds: seeds,
               cvSplitIndex: cvSplitStringifiedIndex.asInt,
               hparams: hparams
            ) 
            // print("Run single test")
            return result
        }
        // for cvFoldStringifiedIndex in getNestedFolderNames(corpusPath) {
        //     print(cvFoldStringifiedIndex.asInt)
        // }
        // return [Metrics]()
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

