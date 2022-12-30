import Swat

struct Corpus: ConfigWithDefaultKeys {
    let path: String
    let enableFilter: Bool
    let dropPatternDuplicates: Bool
    let dropFilterDuplicates: Bool
}
