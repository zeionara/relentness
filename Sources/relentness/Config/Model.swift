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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(encoder.userInfo.postProcess("\(model)"), forKey: AnyKey(stringValue: encoder.userInfo.postProcess("model")))
        try container.encode(hiddenSize, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("hidden_size")))
        try container.encode(reverse, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("reverse")))

        if let entitySize = entitySize {
            try container.encode(entitySize, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("entity_size")))
        }

        if let relationSize = relationSize {
            try container.encode(relationSize, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("relation_size")))
        }
    }
}
