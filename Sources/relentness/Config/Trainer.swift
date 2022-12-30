import Swat

struct Trainer: ConfigWithDefaultKeys {
    let nEpochs: Int
    let batchSize: Int

    let entityNegativeRate: Int
    let relationNegativeRate: Int

    let margin: Double?
}
