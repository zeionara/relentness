import Swat

struct Optimizer_: ConfigWithDefaultKeys {
    enum Optimizer: String, Codable {
        case sgd
        case adamw
    }

    let optimizer: Optimizer
    let alpha: Double
}
