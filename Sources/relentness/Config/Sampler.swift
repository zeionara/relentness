import Swat

struct Sampler_: ConfigWithDefaultKeys {
    enum Pattern: Codable {
        case symmetric
        case inverse
    }

    let pattern: Pattern?
    let nObservedTriplesPerPatternInstance: Int
    let bern: Bool
    let crossSampling: Bool
    let nWorkers: Int
}
