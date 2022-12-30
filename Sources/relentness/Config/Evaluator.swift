import Swat

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
}

extension Evaluator.Task: Codable {

    // enum Key: CodingKey {
    //     case rawValue
    // }

    enum CodingError: Error {
        case unknownValue
    }

    init(from decoder: Decoder) throws {
        // print(try decoder.singleValueContainer().decode(String.self))
        // print("foo")
        // let container = try decoder.container(keyedBy: Key.self)
        // print("bar")
        // let rawValue = try container.decode(String.self, forKey: .rawValue)

        switch try decoder.singleValueContainer().decode(String.self) {
        // switch rawValue {
            case "link-prediction":
                self = .linkPrediction
            case "triple-classification":
                self = .tripleClassification
            default:
                throw CodingError.unknownValue
        }
    }

}

extension Evaluator.Metric: Codable {

    enum Key: String, CodingKey {
        case top
        case tops
        // case associatedValue
        // case rawValue
        // case top = "top-n"
        // case rank
        // case reciprocalRank
        // case n
    }

    enum NestedKey: String, CodingKey {
        // case rawValue
        case n
        case ns
        // case n
    }

    enum CodingError: Error {
        case unknownValue
    }

    init(from decoder: Decoder) throws {
        // print("foo")
        // print(decoder.codingPath)
        // let container = try decoder.unkeyedContainer()
        // print(Key.top)
        // print(decoder)

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

        // let container = try decoder.container(keyedBy: Key.self)
        // // print(container)
        // // print(try container.decode(String.self, forKey: .top)) // *
        // let n = try container.nestedContainer(keyedBy: NestedKey.self, forKey: .top)
        // print(try n.decode(Int.self, forKey: .n)) // *
        // // print(n)
        // // print(decoder.json)
        // // print(decoder)
        // // let container = try decoder.container(keyedBy: Key.self)
        // // print(try container.decode(String.self, forKey: .n))
        // // print(container)
        // print("bar")
        // // let rawValue = try container.decode(String.self, forKey: .rawValue)

        // switch try decoder.singleValueContainer().decode(String.self) {
        //     default:
        //         throw CodingError.unknownValue
        // }
    }

}
