import Foundation
import Yams
import wickedData

public struct Pattern: Codable {
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

    public func getPositiveSample<BindingType: CountableBindingTypeWithAggregation>(_ adapter: BlazegraphAdapter) async throws -> Sample<BindingType> { // TODO: Change blazegraph adapter to an abstract type
        try await adapter.sample(
            getPositiveQuery()
        )
    }

    public func getNegativeSample<BindingType: CountableBindingTypeWithAggregation>(_ adapter: BlazegraphAdapter) async throws -> Sample<BindingType> { // TODO: Change blazegraph adapter to an abstract type
        try await adapter.sample(
            getNegativeQuery(),
            timeout: 3_600_000
        )
    }

    public func getTotalSample(_ adapter: BlazegraphAdapter) async throws -> Sample<CountingQuery.BindingType> { // TODO: Change blazegraph adapter to an abstract type
        try await adapter.sample(
            totalQuery
        )
    }

    public func evaluate<BindingType: CountableBindingTypeWithAggregation>(_ adapter: BlazegraphAdapter) async throws -> PatternStats<BindingType> {
        // let positiveSample: Sample<BindingType> = try await pattern.getPositiveSample(adapter)
        // let negativeSample: Sample<BindingType> = try await pattern.getNegativeSample(adapter)
        // let totalSample = try await pattern.getTotalSample(adapter)

        PatternStats(
            positiveSample: try await getPositiveSample(adapter),
            negativeSample: try await getNegativeSample(adapter),
            totalSample: try await getTotalSample(adapter)
        )
    }
} 

public struct PatternStats<BindingType: CountableBindingTypeWithAggregation>: CustomStringConvertible {
    let positiveSample: Sample<BindingType>
    let negativeSample: Sample<BindingType>
    let totalSample: Sample<CountingQuery.BindingType>
    let threshold: Double = 0.5
    let nDecimalPlaces: Int = 3

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

        return "\(positiveRatio)\t\(negativeRatio)\t\(positiveNormalizedRatio)\t\(negativeNormalizedRatio)\t\(relativeRatio)\t\(positiveCount)\t\(negativeCount)\t\(totalCount)"
    }

    public static var header: String {
        "positive-ratio\tnegative-ratio\tpositive-normalized-ratio\tnegative-normalized-ratio\trelative-ratio\tn-positive-occurrences\tn-negative-occurrences\tn-triples"
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

