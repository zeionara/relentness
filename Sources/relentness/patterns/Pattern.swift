import Foundation
import Yams
import wickedData

public struct Pattern: Codable, Sendable {
    public let name: String
    public let positiveQueryText: String
    public let negativeQueryText: String

    public let totalQuery = CountingQuery(
        text: """
        select (count(?h) as ?count) where {
          ?h ?r ?t.
        }
        """
    )

    enum CodingKeys: String, CodingKey {
        case name
        case positiveQueryText = "positive"
        case negativeQueryText = "negative"
    }

    public func getPositiveQuery<BindingType: CountableBindingTypeWithAggregation>() -> CountingQueryWithAggregation<BindingType> {
        return CountingQueryWithAggregation<BindingType>(
            text: positiveQueryText
        )
    }

    public func getNegativeQuery<BindingType: CountableBindingTypeWithAggregation>() -> CountingQueryWithAggregation<BindingType> {
        return CountingQueryWithAggregation<BindingType>(
            text: negativeQueryText
        )
    }

    public func getPositiveSample<BindingType: CountableBindingTypeWithAggregation>(_ adapter: BlazegraphAdapter, timeout: Int? = nil) async throws -> Sample<BindingType> { // TODO: Change blazegraph adapter to an abstract type
        try await adapter.sample(
            getPositiveQuery(),
            timeout: timeout
        )
    }

    public func getNegativeSample<BindingType: CountableBindingTypeWithAggregation>(_ adapter: BlazegraphAdapter, timeout: Int? = nil) async throws -> Sample<BindingType> { // TODO: Change blazegraph adapter to an abstract type
        try await adapter.sample(
            getNegativeQuery(),
            timeout: timeout // 3_600_000
        )
    }

    public func getTotalSample(_ adapter: BlazegraphAdapter, timeout: Int? = nil) async throws -> Sample<CountingQuery.BindingType> { // TODO: Change blazegraph adapter to an abstract type
        try await adapter.sample(
            totalQuery,
            timeout: timeout
        )
    }

    public func evaluate<BindingType: CountableBindingTypeWithAggregation>(_ adapter: BlazegraphAdapter, timeout: Int? = nil) async throws -> PatternStats<BindingType> {
        // let positiveSample: Sample<BindingType> = try await pattern.getPositiveSample(adapter)
        // let negativeSample: Sample<BindingType> = try await pattern.getNegativeSample(adapter)
        // let totalSample = try await pattern.getTotalSample(adapter)

        try await measureExecutionTime {
            (
                positive: try await getPositiveSample(adapter, timeout: timeout),
                negative: try await getNegativeSample(adapter, timeout: timeout),
                total: try await getTotalSample(adapter, timeout: timeout)
            )
        } handleExecutionTimeMeasurement: { (samples, executionTime) in
            PatternStats(
                positiveSample: samples.positive,
                negativeSample: samples.negative,
                totalSample: samples.total,
                executionTime: executionTime
            )
        }

        // PatternStats(
        //     positiveSample: try await getPositiveSample(adapter),
        //     negativeSample: try await getNegativeSample(adapter),
        //     totalSample: try await getTotalSample(adapter)
        // )
    }
} 

let NO_CELL_VALUE = CellValue.string(value: "-")

public struct PatternStats<BindingType: CountableBindingTypeWithAggregation>: CustomStringConvertible {
    let positiveSample: Sample<BindingType>
    let negativeSample: Sample<BindingType>
    let totalSample: Sample<CountingQuery.BindingType>
    let threshold: Double = 0.5
    let nDecimalPlaces: Int = 3
    let executionTime: Double

    enum Metric: String, CaseIterable {
        case positiveRatio = "positive-ratio"
        case negativeRatio = "negative-ratio"
        case positiveNormalizedRatio = "positive-normalized-ratio"
        case negativeNormalizedRatio = "negative-normalized-ratio"
        case relativeRatio = "relative-ratio"
        case nPositiveOccurrences = "n-positive-occurrences"
        case nNegativeOccurrences = "n-negative-occurrences"
        case nTriples = "n-triples"
        case executionTime = "execution-time"
    }

    private func stringifyDouble(_ value: Double) -> String {
        String(format: "%.\(nDecimalPlaces)f", value)
    }
    
    public var description: String {
        let positiveCount = positiveSample.count(threshold)
        let negativeCount = negativeSample.count(threshold)
        let totalCount = totalSample.count
        let normalizingCount = positiveCount + negativeCount

        let positiveRatio = totalCount == 0 ? "-" : stringifyDouble(Double(positiveCount) / Double(totalCount))
        let negativeRatio = totalCount == 0 ? "-" : stringifyDouble(Double(negativeCount) / Double(totalCount))
        let relativeRatio = negativeCount == 0 ? "-" : stringifyDouble(Double(positiveCount) / Double(negativeCount))

        let positiveNormalizedRatio = normalizingCount == 0 ? "-" : stringifyDouble(Double(positiveCount) / Double(normalizingCount))
        let negativeNormalizedRatio = normalizingCount == 0 ? "-" : stringifyDouble(Double(negativeCount) / Double(normalizingCount))

        let executionTime = stringifyDouble(executionTime)

        return "\(positiveRatio)\t\(negativeRatio)\t\(positiveNormalizedRatio)\t\(negativeNormalizedRatio)\t\(relativeRatio)\t\(positiveCount)\t\(negativeCount)\t\(totalCount)\t\(executionTime)"
    }

    public var descriptionItems: [CellValue] {
        let positiveCountRaw = positiveSample.count(threshold)
        let positiveCount = CellValue.number(value: Double(positiveCountRaw))

        let negativeCountRaw = negativeSample.count(threshold)
        let negativeCount = CellValue.number(value: Double(negativeCountRaw))

        let totalCountRaw = totalSample.count 
        let totalCount = CellValue.number(value: Double(totalCountRaw))

        let normalizingCountRaw = positiveCountRaw + negativeCountRaw
        // let normalizingCount = CellValue.number(value: Double(normalizingCountRaw))

        let positiveRatio = totalCountRaw == 0 ? NO_CELL_VALUE : CellValue.number(value: Double(positiveCountRaw) / Double(totalCountRaw))
        let negativeRatio = totalCountRaw == 0 ? NO_CELL_VALUE : CellValue.number(value: Double(negativeCountRaw) / Double(totalCountRaw))
        let relativeRatio = negativeCountRaw == 0 ? NO_CELL_VALUE : CellValue.number(value: Double(positiveCountRaw) / Double(negativeCountRaw))

        let positiveNormalizedRatio = normalizingCountRaw == 0 ? NO_CELL_VALUE : CellValue.number(value: Double(positiveCountRaw) / Double(normalizingCountRaw))
        let negativeNormalizedRatio = normalizingCountRaw == 0 ? NO_CELL_VALUE : CellValue.number(value: Double(negativeCountRaw) / Double(normalizingCountRaw))

        let executionTime = CellValue.number(value: executionTime)

        return [
            positiveRatio, negativeRatio, positiveNormalizedRatio, negativeNormalizedRatio, relativeRatio, positiveCount, negativeCount, totalCount, executionTime
        ]
    }

    public static var header: String {
        Metric.allCases.map{ $0.rawValue }.joined(separator: "\t")
    }

    public static var headerItems: [CellValue] {
        Metric.allCases.map{ CellValue.string(value: $0.rawValue) }
    }

    var asDict: DatasetTestingResult {
        let positiveCount = positiveSample.count(threshold)
        let negativeCount = negativeSample.count(threshold)
        let totalCount = totalSample.count
        let normalizingCount = positiveCount + negativeCount

        return [
            .positiveRatio: totalCount != 0 ? Double(positiveCount) / Double(totalCount) : -Double.infinity,
            .negativeRatio: totalCount != 0 ? Double(negativeCount) / Double(totalCount) : -Double.infinity,
            .positiveNormalizedRatio: normalizingCount != 0 ?  Double(positiveCount) / Double(normalizingCount) : -Double.infinity,
            .negativeNormalizedRatio: normalizingCount != 0 ? Double(negativeCount) / Double(normalizingCount) : -Double.infinity,
            .relativeRatio: negativeCount != 0 ? Double(positiveCount) / Double(negativeCount) : -Double.infinity,
            .nPositiveOccurrences: Double(positiveCount),
            .nNegativeOccurrences: Double(negativeCount),
            .nTriples: Double(totalCount),
            .executionTime: executionTime
        ]
    }
}

public struct PatternStorage: Codable {
    public let elements: [Pattern]

    enum CodingKeys: String, CodingKey {
        case elements = "items"
    }
}

public struct Patterns {
    let path: String?
    let storage: PatternStorage

    public init(_ path: String) { // TODO: Implement exception handling
        let decoder = YAMLDecoder()
        storage = try! decoder.decode(
            PatternStorage.self, 
            from: try! String(contentsOf: URL.local("./Assets/Patterns/\(path).yml")!, encoding: .utf8)
        )
        self.path = path
    }
}

