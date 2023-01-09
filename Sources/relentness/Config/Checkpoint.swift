import Swat

struct Checkpoint: ConfigWithDefaultKeys {
    let root: String
    let frequency: Int?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(root, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("root")))

        if let frequency = frequency {
            try container.encode(frequency, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("frequency")))
        }
    }
}
