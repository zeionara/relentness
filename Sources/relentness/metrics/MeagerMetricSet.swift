public protocol MetricSet {
    init(_ serialized: String, time: Double?)
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

public let N_DECIMAL_PLACES = 4
public let FLOAT_FORMAT = "%.\(N_DECIMAL_PLACES)f"

infix operator +++: AdditionPrecedence // Dot product operator which is generally defined as tensor-to-tensor multiplications
infix operator /++: MultiplicationPrecedence // Dot product operator which is generally defined as tensor-to-tensor multiplications

public struct MeagerMetricSeries: CustomStringConvertible, Sendable {
    public let meanRank: Double
    public let meanReciprocalRank: Double
    public let hitsAtOne: Double
    public let hitsAtThree: Double
    public let hitsAtTen: Double
    public let time: Double?
    public let totalTime: Double?

    public enum Metric: Int {
        case meanRank = 0
        case meanReciprocalRank = 1
        case hitsAtOne = 2
        case hitsAtThree = 3
        case hitsAtTen = 4
        case time = 5
        case totalTime = 6
        case executionTime = 7
    }

    fileprivate init(meanRank: Double, meanReciprocalRank: Double, hitsAtOne: Double, hitsAtThree: Double, hitsAtTen: Double, time: Double? = nil, totalTime: Double? = nil) {
        self.meanRank = meanRank
        self.meanReciprocalRank = meanReciprocalRank
        self.hitsAtOne = hitsAtOne
        self.hitsAtThree = hitsAtThree
        self.hitsAtTen = hitsAtTen
        self.time = time
        self.totalTime = totalTime
    }

    fileprivate init(_ values: [String], indexMap: MeagerMetricSeriesIndexMap, time: Double? = nil) {
        meanRank = values[indexMap.meanRank].asDouble
        meanReciprocalRank = values[indexMap.meanReciprocalRank].asDouble
        hitsAtOne = values[indexMap.hitsAtOne].asDouble
        hitsAtThree = values[indexMap.hitsAtThree].asDouble
        hitsAtTen = values[indexMap.hitsAtTen].asDouble
        self.time = time
        self.totalTime = nil
    }

    public var descriptionItems: [CellValue] {
        [
            meanRank.round(places: N_DECIMAL_PLACES),
            meanReciprocalRank.round(places: N_DECIMAL_PLACES),
            hitsAtOne.round(places: N_DECIMAL_PLACES),
            hitsAtThree.round(places: N_DECIMAL_PLACES),
            hitsAtTen.round(places: N_DECIMAL_PLACES),
            (time ?? 0.0).round(places: N_DECIMAL_PLACES),
            (totalTime ?? time ?? 0.0).round(places: N_DECIMAL_PLACES)
        ].map{CellValue.number(value: $0)}
    }

    public var description: String {
        [
            String(format: FLOAT_FORMAT, meanRank), String(format: FLOAT_FORMAT, meanReciprocalRank),
            String(format: FLOAT_FORMAT, hitsAtOne), String(format: FLOAT_FORMAT, hitsAtThree), String(format: FLOAT_FORMAT, hitsAtTen),
            stringifiedTime, stringifiedTotalTime
        ].joined(separator: "\t")
    }

    public func descriptionItemsWithExecutionTime(_ executionTime: Double) -> [CellValue] {
        descriptionItems + [CellValue.number(value: executionTime.round(places: N_DECIMAL_PLACES))]
    }

    public func descriptionWithExecutionTime(_ executionTime: Double) -> String {
        [
            String(format: FLOAT_FORMAT, meanRank), String(format: FLOAT_FORMAT, meanReciprocalRank),
            String(format: FLOAT_FORMAT, hitsAtOne), String(format: FLOAT_FORMAT, hitsAtThree), String(format: FLOAT_FORMAT, hitsAtTen),
            stringifiedTime, stringifiedTotalTime, String(format: FLOAT_FORMAT, executionTime)
        ].joined(separator: "\t")
    }

    public var stringifiedTime: String {
       if let unwrappedTime = time {
           return String(format: FLOAT_FORMAT, unwrappedTime) 
       }
       return "-"
    }

    public var unwrappedTime: Double {
        if let unwrappedTime_ = time {
            return unwrappedTime_
        }
        return 0
    }

    public var stringifiedTotalTime: String {
       if let unwrappedTime = totalTime {
          return String(format: FLOAT_FORMAT, unwrappedTime) 
        }
        return stringifiedTime
    }

    public var unwrappedTotalTime: Double {
        if let unwrappedTime_ = totalTime {
            return unwrappedTime_
        }
        return unwrappedTime
    }

    private static let headerItemLabels = ["mr", "mrr", "hits@1", "hits@3", "hits@10", "time", "total-time"]
    private static let headerItemLabelsWithExecutionTime = headerItemLabels + ["execution-time"]

    public static var headerItems: [CellValue] {
        headerItemLabels.map{CellValue.string(value: $0)}
    }

    public static var header: String {
        headerItemLabels.joined(separator: "\t")
    }

    public static var headerItemsWithExecutionTime: [CellValue] {
        headerItemLabelsWithExecutionTime.map{CellValue.string(value: $0)}
    }

    public static var headerWithExecutionTime: String {
        headerItemLabelsWithExecutionTime.joined(separator: "\t")
    }

    public func weightedSum(executionTime: Double? = nil) -> Double {
       0.9 * hitsAtTen + 0.09 * hitsAtThree + 0.01 * hitsAtOne
    } 
}

public extension MeagerMetricSeries {
    static func +(lhs: MeagerMetricSeries, rhs: MeagerMetricSeries) -> MeagerMetricSeries {
        MeagerMetricSeries(
            meanRank: lhs.meanRank + rhs.meanRank,
            meanReciprocalRank: lhs.meanReciprocalRank + rhs.meanReciprocalRank,
            hitsAtOne: lhs.hitsAtOne + rhs.hitsAtOne,
            hitsAtThree: lhs.hitsAtThree + rhs.hitsAtThree,
            hitsAtTen: lhs.hitsAtTen + rhs.hitsAtTen,
            time: lhs.time,
            totalTime: lhs.totalTime
        )
    }

    static func +++(lhs: MeagerMetricSeries, rhs: MeagerMetricSeries) -> MeagerMetricSeries {
        MeagerMetricSeries(
            meanRank: lhs.meanRank + rhs.meanRank,
            meanReciprocalRank: lhs.meanReciprocalRank + rhs.meanReciprocalRank,
            hitsAtOne: lhs.hitsAtOne + rhs.hitsAtOne,
            hitsAtThree: lhs.hitsAtThree + rhs.hitsAtThree,
            hitsAtTen: lhs.hitsAtTen + rhs.hitsAtTen,
            time: lhs.unwrappedTime + rhs.unwrappedTime,
            totalTime: lhs.unwrappedTotalTime + rhs.unwrappedTotalTime
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
            hitsAtTen: lhs.hitsAtTen / rhs,
            time: lhs.time,
            totalTime: lhs.totalTime
        )
    }

    static func /++(lhs: MeagerMetricSeries, rhs: Int) -> MeagerMetricSeries {
        lhs /++ Double(rhs)
    }

    static func /++(lhs: MeagerMetricSeries, rhs: Double) -> MeagerMetricSeries {
        return MeagerMetricSeries(
            meanRank: lhs.meanRank / rhs,
            meanReciprocalRank: lhs.meanReciprocalRank / rhs,
            hitsAtOne: lhs.hitsAtOne / rhs,
            hitsAtThree: lhs.hitsAtThree / rhs,
            hitsAtTen: lhs.hitsAtTen / rhs,
            time: lhs.unwrappedTime / rhs,
            totalTime: lhs.totalTime
        )
    }
}

public struct MeagerMetricSubset: Sendable {
    public let head: MeagerMetricSeries
    public let tail: MeagerMetricSeries
    public let mean: MeagerMetricSeries

    fileprivate init(head: MeagerMetricSeries, tail: MeagerMetricSeries, mean: MeagerMetricSeries) {
        self.head = head
        self.tail = tail
        self.mean = mean
    }

    fileprivate init(_ values: [[String]], indexMap: MeagerMetricSeriesIndexMap, time: Double? = nil) {
        head = MeagerMetricSeries(values[0], indexMap: indexMap, time: time)
        tail = MeagerMetricSeries(values[1], indexMap: indexMap, time: time)
        mean = MeagerMetricSeries(values[2], indexMap: indexMap, time: time)
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

    static func +++(lhs: MeagerMetricSubset, rhs: MeagerMetricSubset) -> MeagerMetricSubset {
        MeagerMetricSubset(
            head: lhs.head +++ rhs.head,
            tail: lhs.tail +++ rhs.tail,
            mean: lhs.mean +++ rhs.mean
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

    static func /++(lhs: MeagerMetricSubset, rhs: Int) -> MeagerMetricSubset {
        lhs /++ Double(rhs)
    }

    static func /++(lhs: MeagerMetricSubset, rhs: Double) -> MeagerMetricSubset {
        return MeagerMetricSubset(
            head: lhs.head /++ rhs,
            tail: lhs.tail /++ rhs,
            mean: lhs.mean /++ rhs
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

    var meanWithAccumulatingTime: Element {
        self[1..<self.count].reduce(
            self.first!,
            +++
        ) /++ self.count
    }
}

public struct MeagerMetricSet: MetricSet, CustomStringConvertible, Sendable {
    public let subsets: [MeagerMetricSubset]
    public let description: String

    public init(_ serialized: String, time: Double? = nil) {
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
                        indexMap: indexMap,
                        time: time
                    ),
                    MeagerMetricSubset(
                        rows[(i * nLinesPerBlock + 4)..<(i * nLinesPerBlock + 7)].map{$0.tabSeparatedValues},
                        indexMap: indexMap,
                        time: time
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
        // print("Averaging array with meager metric sets which contains \(self.count) elements (presumably each of which corresponds to a seed)")
        assert(self.count > 0)
        assert(self.dropFirst().allSatisfy{ $0.subsets.count == self.first!.subsets.count })

        let result = MeagerMetricSet(
            (0..<self.first!.subsets.count).map{ i in // The loop returns an array in which number of elements must be equal to number of subsets in each of base objects
                self.map{ metricSet in
                    metricSet.subsets[i]
                }.meanWithAccumulatingTime
            }
        )

        assert(result.subsets.count == self.first!.subsets.count)
        return result
    }
}

public func mean(sets: [[MeagerMetricSet]]) -> [MeagerMetricSet] {
    // print("Averaging array with meager metric sets which contains \(sets.count) elements (presumably each of which corresponds to a cv split)")
    assert(sets.count > 0)
    assert(sets.dropFirst().allSatisfy{ $0.count == sets.first!.count })

    let result = (0..<sets.first!.count).map{ i in // The method returns an array in which number of elements must be equal to the number of provided seeds
        return sets.map{ metricSetList in
            metricSetList[i]
        }.mean
    }

    assert(result.count == sets.first!.count)
    return result
}

