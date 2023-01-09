import Swat

enum CodingError: Error {
    case unknownValue
}

struct Evaluator: ConfigWithDefaultKeys {
    enum Metric {
        case top(n: Int)
        case rank
        case reciprocalRank
    }

    enum Task {
        case linkPrediction
        case tripleClassification
    }

    let task: Task
    let metrics: [Metric]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(task, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("task")))
        try container.encode(metrics, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("metrics")))
    }
}

extension Evaluator.Task: Codable {

    init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
            case "link-prediction":
                self = .linkPrediction
            case "triple-classification":
                self = .tripleClassification
            default:
                throw CodingError.unknownValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(
            encoder.userInfo.postProcess(
                "\(self)"
            )
        )
    }

}

extension Evaluator.Metric: Codable {

    enum Key: String, CodingKey {
        case top
    }

    enum NestedKey: String, CodingKey {
        case n
    }

    enum EncodedTop: String, CodingKey {
        case n
    }

    init(from decoder: Decoder) throws {
        if let metrics = try? decoder.container(keyedBy: Key.self), let top = try? metrics.nestedContainer(keyedBy: NestedKey.self, forKey: .top), let n = try? top.decode(Int.self, forKey: .n) {
            self = .top(n: n)
        } else if let metric = try? decoder.singleValueContainer().decode(String.self) {
            switch metric {
                case "rank":
                    self = .rank
                case "reciprocal-rank":
                    self = .reciprocalRank
                default:
                    throw CodingError.unknownValue
            }
        } else {
            throw CodingError.unknownValue
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
            case .rank, .reciprocalRank:
                var container = encoder.unkeyedContainer()
                try container.encode(
                    encoder.userInfo.postProcess(
                        "\(self)"
                    )
                )
            case let .top(n: n):
                var container = encoder.unkeyedContainer()
                try container.encode(
                    encoder.userInfo.postProcess(
                        "topN"
                    )
                )
                try container.encode(n)
        }
    }

}
