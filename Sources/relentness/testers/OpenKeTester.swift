import Foundation

public protocol Tester {
    associatedtype Metrics: MetricSet

    func runSingleTest(seed: Int?) async throws -> Metrics
    func runSingleTest(seeds: [Int]?) async throws -> [Metrics]
    func run(seeds: [Int]?) async throws -> [[Metrics]]
}

public enum OpenKeModel: String {
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

    public init(model: OpenKeModel, env: String, corpus: String, nWorkers: Int? = nil) {
        self.model = model
        self.env = env
        self.corpus = corpus
        self.nWorkers = nWorkers
    }

    public func runSingleTest(seed: Int? = nil) async throws -> Metrics {
        try await runSingleTest(seed: seed, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX)
    }

    public func runSingleTest(seed: Int? = nil, cvSplitIndex: Int) async throws -> Metrics {
        var args = ["-m", "relentness", "test", "\(corpusPath)/\(String(format: "%04i", cvSplitIndex))/", "-m", model.rawValue, "-t"]
        if let unwrappedSeed = seed {
            args.append(
                contentsOf: ["-s", String(describing: unwrappedSeed)]
            )
        }

        // let output = 
        return try await measureExecutionTime {
            try await runSubprocessAndGetOutput(
                path: "/home/\(USER)/anaconda3/envs/\(env)/bin/python",
                args: args,
                env: ["TF_CPP_MIN_LOG_LEVEL": "3"]
            )
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

    public func runSingleTest(seeds: [Int]? = nil, cvSplitIndex: Int) async throws -> [Metrics] {
        if let unwrappedSeeds = seeds {
            // let results = seeds.map{ seed in
            //     runSingleTest(
            //         seed: seed
            //     )
            // }
            return try await unwrappedSeeds.asyncMap(nWorkers: nWorkers) { seed in // TODO: Add support for total time (instead of computing sum, here max must me chosen)
                try await runSingleTest(
                   seed: seed,
                   cvSplitIndex: cvSplitIndex
                ) 
            }
        }

        let result: Metrics = try await runSingleTest(cvSplitIndex: cvSplitIndex)
        return [result]
    }

    public func run(seeds: [Int]? = nil) async throws -> [[Metrics]] {
        return try await getNestedFolderNames(corpusPath).asyncMap(nWorkers: 1) { cvSplitStringifiedIndex in // No parallelism on this level
            try await runSingleTest(
               seeds: seeds,
               cvSplitIndex: cvSplitStringifiedIndex.asInt
            ) 
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

