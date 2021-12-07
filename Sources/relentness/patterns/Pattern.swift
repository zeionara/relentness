import Foundation
import Yams
import wickedData
import Logging

public extension String {
    var containsPatternPlaceHolders: Bool {
        contains(Pattern.limitPlaceHolder) && contains(Pattern.offsetPlaceHolder)
    }
}

public enum PatternKind {
    case positive, negative
}

private struct BatchIterator: IteratorProtocol {
    typealias Element = (limit: Int, offset: Int)

    let limit: Int
    var offset: Int = 0

    mutating func next() -> Self.Element? {
        let nextItem = (limit: limit, offset: offset)

        offset += limit

        return nextItem
    }
}

public struct Pattern: Codable, Sendable {
    fileprivate static let limitPlaceHolder = "{{limit}}"
    fileprivate static let offsetPlaceHolder = "{{offset}}"

    public let name: String
    public let positiveQueryText: String
    public let negativeQueryText: String

    public let positiveBatched: String? // TODO: Delete this

    public let batchSize: Int?

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
        case batchSize = "batch-size"
        case positiveBatched // TODO: Delete this
    }

    public static func fillBatchSizePlaceHolders(_ query: String, limit: Int? = nil, offset: Int? = nil) -> String {
        if let limitUnwrapped = limit, let offsetUnwrapped = offset {
            let stringifiedLimit = String(limitUnwrapped)
            let stringifiedOffset = String(offsetUnwrapped)

            return query.replacingOccurrences(of: Pattern.limitPlaceHolder, with: stringifiedLimit).replacingOccurrences(of: Pattern.offsetPlaceHolder, with: stringifiedOffset)
        }

        return query
    }

    // public func getPositiveQuery<BindingType: CountableBindingTypeWithAggregation>(limit: Int? = nil, offset: Int? = nil) -> CountingQueryWithAggregation<BindingType> {
    //     let query = Pattern.fillBatchSizePlaceHolders(positiveQueryText, limit: limit, offset: offset) // positiveQueryText

    //     // if let limitUnwrapped = limit, let offsetUnwrapped = offset {
    //     //     let stringifiedLimit = String(limitUnwrapped)
    //     //     let stringifiedOffset = String(offsetUnwrapped)

    //     //     query = positiveBatched!.replacingOccurrences(of: Pattern.limitPlaceHolder, with: stringifiedLimit).replacingOccurrences(of: Pattern.offsetPlaceHolder, with: stringifiedOffset)
    //     // }

    //     return CountingQueryWithAggregation<BindingType>(
    //         text: query
    //     )
    // }

    public func getQuery<BindingType: CountableBindingTypeWithAggregation>(_ text: String, limit: Int? = nil, offset: Int? = nil) -> CountingQueryWithAggregation<BindingType> {
        let query = Pattern.fillBatchSizePlaceHolders(text, limit: limit, offset: offset) // positiveQueryText

        return CountingQueryWithAggregation<BindingType>(
            text: query
        )
    }

    public func getSample<BindingType: CountableBindingTypeWithAggregation>(
        _ adapter: BlazegraphAdapter, query: String, timeout: Int? = nil,
        logger: Logger? = nil, pattern: String? = nil, kind: PatternKind? = nil, nWorkers: Int? = nil
    ) async throws -> Sample<BindingType> { // TODO: Change blazegraph adapter to an abstract type
        // print("Getting positive sample...")

        if let batchSizeUnwrapped = batchSize, query.containsPatternPlaceHolders {
            // print("Batch size = \(batchSizeUnwrapped)")

            // var offset = 0
            // var index = 0

            // var partialSamples = [Sample<BindingType>]()

            var batchIterator = BatchIterator(limit: batchSizeUnwrapped)

            let samples = try await batchIterator.asyncDo(nWorkers: nWorkers) { (item, _, index) in
                try await measureExecutionTime { () -> Sample<BindingType> in
                    try await adapter.sample(getQuery(query, limit: item.limit, offset: item.offset), timeout: timeout)
                } handleExecutionTimeMeasurement: { (sample, executionTime) -> Sample<BindingType> in 
                    logger.trace(
                        "Processed \(index)th query batch (limit = \(item.limit), offset = \(item.offset), n-bindings = \(sample.nBindings), evaluation-time = \(executionTime) seconds) for " +
                        ((kind ?? .positive) == .negative ? "negative" : "") +
                        " pattern \(pattern ?? "")"
                    )
                    return sample
                }
            } until: { sample in
                sample.nBindings == 0
            }

            // while true {
            //     print(batchIterator.next()!)
            //     index += 1
            //     // let foo: CountingQueryWithAggregation<BindingType> = getPositiveQuery(limit: limit, offset: offset)
            //     // print(try await adapter.sample(foo).nBindings)

            //     let partialSample: Sample<BindingType> = try await measureExecutionTime { () -> Sample<BindingType> in
            //         try await adapter.sample(getQuery(query, limit: batchSizeUnwrapped, offset: offset), timeout: timeout)
            //     } handleExecutionTimeMeasurement: { sample, executionTime in 
            //         logger.trace(
            //             "Processed \(index)th query batch (limit = \(batchSizeUnwrapped), offset = \(offset), n-bindings = \(sample.nBindings), evaluation-time = \(executionTime) seconds) for " +
            //             ((kind ?? .positive) == .negative ? "negative" : "") +
            //             " pattern \(pattern ?? "")"
            //         )
            //         return sample
            //     }

            //     if partialSample.nBindings == 0 {
            //         break
            //     }

            //     partialSamples.append(partialSample)
            //     offset += batchSizeUnwrapped
            // }

            return try join(samples)
        }

        // return try await adapter.sample(
        //     getQuery(query),
        //     timeout: timeout
        // )

        return try await measureExecutionTime { () -> Sample<BindingType> in
            try await adapter.sample(getQuery(query), timeout: timeout)
        } handleExecutionTimeMeasurement: { sample, executionTime in 
            logger.trace(
                "Processed query (n-bindings = \(sample.nBindings), evaluation-time = \(executionTime) seconds) for " +
                ((kind ?? .positive) == .negative ? "negative " : "") +
                "pattern \(pattern ?? "")"
            )
            return sample
        }
    }

    public func getTotalSample(_ adapter: BlazegraphAdapter, timeout: Int? = nil) async throws -> Sample<CountingQuery.BindingType> { // TODO: Change blazegraph adapter to an abstract type
        try await adapter.sample(
            totalQuery,
            timeout: timeout
        )
    }

    public func evaluate<BindingType: CountableBindingTypeWithAggregation>(
        _ adapter: BlazegraphAdapter, timeout: Int? = nil, logger: Logger? = nil, pattern: String? = nil, nWorkers: Int? = nil
    ) async throws -> PatternStats<BindingType> {
        
        // let positiveSample: Sample<BindingType> = try await pattern.getPositiveSample(adapter)
        // let negativeSample: Sample<BindingType> = try await pattern.getNegativeSample(adapter)
        // let totalSample = try await pattern.getTotalSample(adapter)

        return try await measureExecutionTime {
            (
                positive: try await getSample(adapter, query: positiveQueryText, timeout: timeout, logger: logger, pattern: pattern, kind: .positive, nWorkers: nWorkers),
                negative: try await getSample(adapter, query: negativeQueryText, timeout: timeout, logger: logger, pattern: pattern, kind: .negative, nWorkers: nWorkers),
                total: try await getTotalSample(adapter, timeout: timeout) // TODO: Extend signature according to the positive and negative pattern evaluators
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

