import Swat

struct Trainer: ConfigWithDefaultKeys {
    let nEpochs: Int
    let batchSize: Int

    let entityNegativeRate: Int
    let relationNegativeRate: Int

    let margin: Double?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(nEpochs, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("nEpochs")))
        try container.encode(batchSize, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("batchSize")))

        try container.encode(entityNegativeRate, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("entityNegativeRate")))
        try container.encode(relationNegativeRate, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("relationNegativeRate")))

        if let margin = margin {
            try container.encode(margin, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("margin")))
        }
    }
}
