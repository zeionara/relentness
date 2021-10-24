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

let N_DECIMAL_PLACES = 3
let FLOAT_FORMAT = "%.\(N_DECIMAL_PLACES)f"

public struct MeagerMetricSeries: CustomStringConvertible {
    public let meanRank: Double
    public let meanReciprocalRank: Double
    public let hitsAtOne: Double
    public let hitsAtThree: Double
    public let hitsAtTen: Double

    fileprivate init(meanRank: Double, meanReciprocalRank: Double, hitsAtOne: Double, hitsAtThree: Double, hitsAtTen: Double) {
        self.meanRank = meanRank
        self.meanReciprocalRank = meanReciprocalRank
        self.hitsAtOne = hitsAtOne
        self.hitsAtThree = hitsAtThree
        self.hitsAtTen = hitsAtTen
    }

    fileprivate init(_ values: [String], indexMap: MeagerMetricSeriesIndexMap) {
        meanRank = values[indexMap.meanRank].asDouble
        meanReciprocalRank = values[indexMap.meanReciprocalRank].asDouble
        hitsAtOne = values[indexMap.hitsAtOne].asDouble
        hitsAtThree = values[indexMap.hitsAtThree].asDouble
        hitsAtTen = values[indexMap.hitsAtTen].asDouble
    }

    public var description: String {
        "\(String(format: FLOAT_FORMAT, meanRank))\t\(String(format: FLOAT_FORMAT, meanReciprocalRank))\t" +
        "\(String(format: FLOAT_FORMAT, hitsAtOne))\t\(String(format: FLOAT_FORMAT, hitsAtThree))\t\(String(format: FLOAT_FORMAT, hitsAtTen))"        
    }

    public static var header: String {
        "mr\tmrr\thits@1\thits@3\thits@10"
    }
}

public extension MeagerMetricSeries {
    static func +(lhs: MeagerMetricSeries, rhs: MeagerMetricSeries) -> MeagerMetricSeries {
        MeagerMetricSeries(
            meanRank: lhs.meanRank + rhs.meanRank,
            meanReciprocalRank: lhs.meanReciprocalRank + rhs.meanReciprocalRank,
            hitsAtOne: lhs.hitsAtOne + rhs.hitsAtOne,
            hitsAtThree: lhs.hitsAtThree + rhs.hitsAtThree,
            hitsAtTen: lhs.hitsAtTen + rhs.hitsAtTen
        )
    }

    static func /(lhs: MeagerMetricSeries, rhs: Int) -> MeagerMetricSeries {
        lhs / Double(rhs)
        // let rhsAsDouble = Double(rhs)

        // return MeagerMetricSeries(
        //     meanRank: lhs.meanRank / rhsAsDouble,
        //     meanReciprocalRank: lhs.meanReciprocalRank / rhsAsDouble,
        //     hitsAtOne: lhs.hitsAtOne / rhsAsDouble,
        //     hitsAtThree: lhs.hitsAtThree / rhsAsDouble,
        //     hitsAtTen: lhs.hitsAtTen / rhsAsDouble
        // )
    }

    static func /(lhs: MeagerMetricSeries, rhs: Double) -> MeagerMetricSeries {
        return MeagerMetricSeries(
            meanRank: lhs.meanRank / rhs,
            meanReciprocalRank: lhs.meanReciprocalRank / rhs,
            hitsAtOne: lhs.hitsAtOne / rhs,
            hitsAtThree: lhs.hitsAtThree / rhs,
            hitsAtTen: lhs.hitsAtTen / rhs
        )
    }
}

public struct MeagerMetricSubset {
    public let head: MeagerMetricSeries
    public let tail: MeagerMetricSeries
    public let mean: MeagerMetricSeries

    fileprivate init(head: MeagerMetricSeries, tail: MeagerMetricSeries, mean: MeagerMetricSeries) {
        self.head = head
        self.tail = tail
        self.mean = mean
    }

    fileprivate init(_ values: [[String]], indexMap: MeagerMetricSeriesIndexMap) {
        head = MeagerMetricSeries(values[0], indexMap: indexMap)
        tail = MeagerMetricSeries(values[1], indexMap: indexMap)
        mean = MeagerMetricSeries(values[2], indexMap: indexMap)
    }
}

public extension MeagerMetricSubset {
    static func +(lhs: MeagerMetricSubset, rhs: MeagerMetricSubset) -> MeagerMetricSubset {
        MeagerMetricSubset(
            head: lhs.head + rhs.head,
            tail: lhs.tail + rhs.tail,
            mean: lhs.mean + rhs.mean
        )
    }

    static func /(lhs: MeagerMetricSubset, rhs: Int) -> MeagerMetricSubset {
        lhs / Double(rhs)
        // let rhsAsDouble = Double(rhs)

        // return MeagerMetricSubset(
        //     head: lhs.head / rhsAsDouble,
        //     tail: lhs.tail / rhsAsDouble,
        //     mean: lhs.mean / rhsAsDouble
        // )
    }

    static func /(lhs: MeagerMetricSubset, rhs: Double) -> MeagerMetricSubset {
        return MeagerMetricSubset(
            head: lhs.head / rhs,
            tail: lhs.tail / rhs,
            mean: lhs.mean / rhs
        )
    }
}


private let nLinesPerBlock = 7

public extension Array where Element == MeagerMetricSubset {
    var mean: Element {
        self[1..<self.count].reduce(
            self.first!,
            +
        ) / self.count
    }
}

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

    public init(_ subsets: [MeagerMetricSubset]) {
        self.subsets = subsets
        self.description = "No string representation because the metric set was generated as a result of averaging other metricsets"
    }

    public var mean: MeagerMetricSubset {
        subsets.mean
    }
}

public extension Array where Element == MeagerMetricSet {
    var mean: MeagerMetricSet {
        MeagerMetricSet(
            (0..<self.count).map{ i in
                self.map{ metricSet in
                    metricSet.subsets[i]
                }.mean
            }
        )
    }
}

public func mean(sets: [[MeagerMetricSet]]) -> [MeagerMetricSet] {
    (0..<sets.count).map{ i in
        sets.map{ metricSetList in
            metricSetList[i]
        }.mean
    }
}

