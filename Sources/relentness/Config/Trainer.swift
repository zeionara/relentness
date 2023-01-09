import Swat

struct Trainer: ConfigWithDefaultKeys {
    let nEpochs: Int
    let batchSize: Int

    let entityNegativeRate: Int
    let relationNegativeRate: Int

    let margin: Double?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(nEpochs, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("n_epochs")))
        try container.encode(batchSize, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("batch_size")))

        try container.encode(entityNegativeRate, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("entity_negative_rate")))
        try container.encode(relationNegativeRate, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("relation_negative_rate")))

        if let margin = margin {
            try container.encode(margin, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("margin")))
        }
    }
}
