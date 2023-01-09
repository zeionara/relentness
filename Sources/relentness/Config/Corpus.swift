import Swat

struct Corpus: ConfigWithDefaultKeys {
    let path: String
    let enableFilter: Bool
    let dropPatternDuplicates: Bool
    let dropFilterDuplicates: Bool

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(path, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("path")))
        try container.encode(encoder.userInfo.postProcessBool(enableFilter), forKey: AnyKey(stringValue: encoder.userInfo.postProcess("enableFilter")))
        try container.encode(encoder.userInfo.postProcessBool(dropPatternDuplicates), forKey: AnyKey(stringValue: encoder.userInfo.postProcess("dropPatternDuplicates")))
        try container.encode(encoder.userInfo.postProcessBool(dropFilterDuplicates), forKey: AnyKey(stringValue: encoder.userInfo.postProcess("dropFilterDuplicates")))
    }
}
