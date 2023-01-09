import Swat

struct Sampler_: ConfigWithDefaultKeys {
    enum Pattern: String, Codable {
        case symmetric
        case inverse
    }

    let pattern: Pattern?
    let nObservedTriplesPerPatternInstance: Int
    let bern: Bool
    let crossSampling: Bool
    let nWorkers: Int

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(nObservedTriplesPerPatternInstance, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("nObservedTriplesPerPatternInstance")))
        try container.encode(encoder.userInfo.postProcessBool(bern), forKey: AnyKey(stringValue: encoder.userInfo.postProcess("bern")))
        try container.encode(encoder.userInfo.postProcessBool(crossSampling), forKey: AnyKey(stringValue: encoder.userInfo.postProcess("crossSampling")))
        try container.encode(nWorkers, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("nWorkers")))

        // if let pattern = pattern {
        try container.encode(pattern?.rawValue, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("pattern")))
        // }
    }
}
