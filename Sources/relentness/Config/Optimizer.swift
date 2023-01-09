import Swat

struct Optimizer_: ConfigWithDefaultKeys {
    enum Optimizer: String, Codable {
        case sgd
        case adamw
    }

    let optimizer: Optimizer
    let alpha: Double

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(encoder.userInfo.postProcess(optimizer.rawValue), forKey: AnyKey(stringValue: encoder.userInfo.postProcess("optimizer")))
        try container.encode(alpha, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("alpha")))
    }
}
