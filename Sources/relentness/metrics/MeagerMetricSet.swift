public extension String {
    var rows: [String] {
        self.components(separatedBy: "\n")
    }

    var tabSeparatedValues: [String] {
        self.components(separatedBy: "\t")
    }

    var asDouble: Double {
        Double(self)!
    }
}

public protocol MetricSet {
    init(_ serialized: String)
}

private struct MeagerMetricSeriesIndexMap {
    let meanRank: Int
    let meanReciprocalRank: Int
    let hitsAtOne: Int
    let hitsAtThree: Int
    let hitsAtTen: Int

    init(_ serialized: String) {
       let serializedAsTsv = serialized.tabSeparatedValues 

       meanRank = serializedAsTsv.firstIndex(of: "MR")! 
       meanReciprocalRank = serializedAsTsv.firstIndex(of: "MRR")!
       hitsAtOne = serializedAsTsv.firstIndex(of: "hit@1")!
       hitsAtThree = serializedAsTsv.firstIndex(of: "hit@3")!
       hitsAtTen = serializedAsTsv.firstIndex(of: "hit@10")!
    }
}

public struct MeagerMetricSeries {
    public let meanRank: Double
    public let meanReciprocalRank: Double
    public let hitsAtOne: Double
    public let hitsAtThree: Double
    public let hitsAtTen: Double

    fileprivate init(_ values: [String], indexMap: MeagerMetricSeriesIndexMap) {
        meanRank = values[indexMap.meanRank].asDouble
        meanReciprocalRank = values[indexMap.meanReciprocalRank].asDouble
        hitsAtOne = values[indexMap.hitsAtOne].asDouble
        hitsAtThree = values[indexMap.hitsAtThree].asDouble
        hitsAtTen = values[indexMap.hitsAtTen].asDouble
    }
}

public struct MeagerMetricSubset {
    public let head: MeagerMetricSeries
    public let tail: MeagerMetricSeries
    public let mean: MeagerMetricSeries

    fileprivate init(_ values: [[String]], indexMap: MeagerMetricSeriesIndexMap) {
        head = MeagerMetricSeries(values[0], indexMap: indexMap)
        tail = MeagerMetricSeries(values[1], indexMap: indexMap)
        mean = MeagerMetricSeries(values[2], indexMap: indexMap)
    }
}

private let nLinesPerBlock = 7

public struct MeagerMetricSet: MetricSet, CustomStringConvertible {
    public let subsets: [MeagerMetricSubset]
    public let description: String

    public init(_ serialized: String) {
        description = serialized

        let rows = serialized.rows
        var subsets = [MeagerMetricSubset]()

        for i in 0..<rows.count / nLinesPerBlock {
            // let header = rows[i * nLinesPerBlock].tabSeparatedValues        
            let indexMap = MeagerMetricSeriesIndexMap(rows[i * nLinesPerBlock])

            subsets.append(
                contentsOf: [
                    MeagerMetricSubset(
                        rows[(i * nLinesPerBlock + 1)..<(i * nLinesPerBlock + 4)].map{$0.tabSeparatedValues},
                        indexMap: indexMap
                    ),
                    MeagerMetricSubset(
                        rows[(i * nLinesPerBlock + 4)..<(i * nLinesPerBlock + 7)].map{$0.tabSeparatedValues},
                        indexMap: indexMap
                    )
                ]
            )
        }

        self.subsets = subsets
    }
}
    
