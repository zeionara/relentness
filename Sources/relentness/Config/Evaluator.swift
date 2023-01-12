import Swat

enum CodingError: Error {
    case unknown(value: String)
    case cannotEncode(metric: String)
}

struct Evaluator: ConfigWithDefaultKeys {
    enum Metric: Hashable {
        case top(n: Int)
        case rank
        case reciprocalRank
        case time

        var asColumnHeader: String {
            switch self {
                case .top(let n):
                    return "top@\(n)"
                case .rank:
                    return "rank"
                case .reciprocalRank:
                    return "reciprocal-rank"
                case .time:
                    return "time"
            }
        }
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
                throw CodingError.unknown(value: "unknown")
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
                    throw CodingError.unknown(value: metric)
            }
        } else {
            throw CodingError.unknown(value: "unknown")
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
            case .time:
                throw CodingError.cannotEncode(metric: "\(self)")
        }
    }

    static func decode(from bytes: [UInt8], startingAt offset: inout Int) throws -> Self {
        let length = bytes[offset]

        offset += 1

        let (offset_, name) = bytes.decode(startingAt: offset)
        offset = offset_
        offset += 1

        if (length > 0) {
            let n: Int = bytes.decode(startingAt: offset)

            offset += 2

            // print(name, n)

            if name == "top_n" {
                return .top(n: n)
            }
        }

        if name == "rank" {
            return .rank
        }
        if name == "reciprocal_rank" {
            return .reciprocalRank
        }

        throw CodingError.unknown(value: name)
    }
}
