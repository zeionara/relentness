import Swat

struct Model_: ConfigWithDefaultKeys {
    enum Model: String, Codable {
        case transe
    }

    let model: Model
    let hiddenSize: Int
    let reverse: Bool

    let entitySize: Int?
    let relationSize: Int?
}
