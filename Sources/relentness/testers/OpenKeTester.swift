import Foundation

public protocol Tester {
    associatedtype Metrics: MetricSet

    func runSingleTest(seed: Int?) async throws -> Metrics
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

    public init(model: OpenKeModel, env: String, corpus: String) {
        self.model = model
        self.env = env
        self.corpus = corpus
    }

    public func runSingleTest(seed: Int? = nil) async throws -> Metrics {
        try await runSingleTest(seed: seed, cvSplitIndex: DEFAULT_CV_SPLIT_INDEX)
    }

    public func runSingleTest(seed: Int? = nil, cvSplitIndex: Int) async throws -> Metrics {
        var args = ["-m", "relentness", "test", "./Assets/Corpora/\(corpus)/\(String(format: "%04i", cvSplitIndex))/", "-m", model.rawValue, "-t"]
        if let unwrappedSeed = seed {
            args.append(
                contentsOf: ["-s", String(describing: unwrappedSeed)]
            )
        }

        let output = try await runSubprocessAndGetOutput(
            path: "/home/\(USER)/anaconda3/envs/\(env)/bin/python",
            args: args,
            env: ["TF_CPP_MIN_LOG_LEVEL": "3"]
        )

        return MeagerMetricSet(output)
    }
}

