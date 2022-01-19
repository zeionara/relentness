import Foundation
import Yams
import wickedData
import Logging

public let maxNWastedAttempts: Int = 10
public let initialDelay: Double = 0.5
public let maxTimeout: Int = 3600_000_000 // 1 0000 hours

public extension String {
    var containsPatternPlaceHolders: Bool {
        contains(Pattern.limitPlaceHolder) && contains(Pattern.offsetPlaceHolder)
    }
}

public enum PatternKind {
    case positive, negative
}

struct BatchIterator: IteratorProtocol {
    typealias Element = (limit: Int, offset: Int)

    let limit: Int
    var offset: Int = 0

    mutating func next() -> Self.Element? {
        let nextItem = (limit: limit, offset: offset)

        offset += limit

        return nextItem
    }
}

enum WorkloadDistributionError: Error {
    case cannotDistributeWorkloadEvenly(item: BatchIterator.Element, index: [Int])
}

// enum QueryGenerationError: Error {
//     case cannotGenerateQuery(comment: String)
// }

public actor TerminationManager {
    private var indicesOfEmptyResults = [[Int]]() 
    public let minConsecutiveEmptyResults = 30

    private static func getPreviousIndex(_ index: [Int]) -> [Int] {
        let indexLength = index.count
        var lastDecrementableDimension: Int = 0

        for i in (1..<indexLength).reversed() {
            if index[i] > 0 {
               lastDecrementableDimension = i
               break
            }
        }

        return (0..<lastDecrementableDimension).map{index[$0]} + [index[lastDecrementableDimension] - 1] // + ((lastDecrementableDimension + 1)..<indexLength).map{_ in nil}
    }

    private static func doesMatchPreviousIndex(_ index: [Int], _ previousIndex: [Int]) -> Bool {
        if index.count < previousIndex.count {
            return false
        } 

        for i in 0..<previousIndex.count {
            if index[i] != previousIndex[i] {
                return false
            }
        }

        return true
    }

    public func findPreviousIndex(_ index: [Int]) -> [Int]? {
        let previousIndex = TerminationManager.getPreviousIndex(index)

        let candidatePreviousIndices = indicesOfEmptyResults.filter{
            TerminationManager.doesMatchPreviousIndex($0, previousIndex)
        }

        if candidatePreviousIndices.count < 1 {
            return nil
        }

        if candidatePreviousIndices.count == 1 {
            return candidatePreviousIndices.first!
        }

        return candidatePreviousIndices.sorted{
            for i in 0..<[$0.count, $1.count].min()! {
                if $0[i] < $1[i] {
                   return true
                } else if $0[i] > $1[i] {
                    return false
                } 
            } 

            return $0.count < $1.count
        }.last!
    }

    public func shouldStop<Element>(results: [Element], index: [Int]) -> Bool {
        if results.count > 0 {
            return false
        } 

        var currentIndex = index

        for _ in 1..<minConsecutiveEmptyResults {
            guard let nextIndex = findPreviousIndex(currentIndex) else {
                indicesOfEmptyResults.append(index)
                return false
            }
            currentIndex = nextIndex
            // if !indicesOfEmptyResults.contains(index - i) {
            //     indicesOfEmptyResults.append(index)
            //     return false
            // }
        }
        return true
    }

    public func shouldStop(receivedStopIndicator: Bool, index: [Int]) -> Bool {
        if !receivedStopIndicator {
            return false
        } 

        var currentIndex = index

        for _ in 1..<minConsecutiveEmptyResults {
            guard let nextIndex = findPreviousIndex(currentIndex) else {
                indicesOfEmptyResults.append(index)
                return false
            }
            currentIndex = nextIndex
            // if !indicesOfEmptyResults.contains(index - i) {
            //     indicesOfEmptyResults.append(index)
            //     return false
            // }
        }
        return true
    }

    // public func shouldStop(receivedStopIndicator: Bool, index: Int) -> Bool {
    //     if !receivedStopIndicator {
    //         return false
    //     } 

    //     for i in 1..<minConsecutiveEmptyResults {
    //         if !indicesOfEmptyResults.contains(index - i) {
    //             indicesOfEmptyResults.append(index)
    //             return false
    //         }
    //     }
    //     return true
    // }
}

public struct Pattern: Codable, Sendable {
    fileprivate static let limitPlaceHolder = "{{limit}}"
    fileprivate static let offsetPlaceHolder = "{{offset}}"

    public let name: String

    public let positiveQueryText: PatternQuery
    public let negativeQueryText: PatternQuery

    public let negativeQueryGenerator: PatternQuery?
    public let positiveQueryGenerator: PatternQuery?

    public let positiveBatched: String? // TODO: Delete this

    public let batchSize: Int?
    public let enabled: Bool?

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
        case negativeQueryGenerator = "negative-generator"
        case positiveQueryGenerator = "positive-generator"
        case positiveBatched // TODO: Delete this
        case enabled
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

    public func getQueryGenerator(_ text: String, limit: Int? = nil, offset: Int? = nil) -> PatternQueryGenerator {
        let query = Pattern.fillBatchSizePlaceHolders(text, limit: limit, offset: offset)

        return PatternQueryGenerator(
            text: query
        )
    }

    public func getSample<BindingType: CountableBindingTypeWithAggregation>(
        _ adapter: BlazegraphAdapter, query: String, timeout: Int? = nil,
        logger: Logger? = nil, pattern: String? = nil, kind: PatternKind? = nil, nWorkers: Int? = nil, queryGenerator: String? = nil
    ) async throws -> Sample<BindingType> { // TODO: Change blazegraph adapter to an abstract type
        // print("Getting sample for pattern \(pattern) with batch size \(batchSize)...")

        if let batchSizeUnwrapped = batchSize {
            // print("baz")
            // print(queryGenerator)
            if let generatorUnwrapped = queryGenerator, generatorUnwrapped.containsPatternPlaceHolders {
                // let terminationManager = TerminationManager()
                // print("Query generator:")
                // print(try await adapter.sample(getQueryGenerator(generatorUnwrapped, limit: 16, offset: 48), timeout: timeout).query)

                // print("foo")
                var batchIterator = BatchIterator(limit: batchSizeUnwrapped)
                // print("bar")

                let samples = try await batchIterator.asyncDo(nWorkers: nWorkers) { (item, workerIndex, index) -> Sample<BindingType> in
                    logger.trace("Processing query for pattern \(pattern)")
                    do {
                        return try await measureExecutionTime { () -> Sample<BindingType> in
                            let query: CountingQueryWithAggregation<BindingType> = getQuery(
                                    try await adapter.sample(
                                        getQueryGenerator(generatorUnwrapped, limit: item.limit, offset: item.offset),
                                        timeout: item.limit == 1 ? maxTimeout : timeout,
                                        maxNWastedAttempts: item.limit == 1 ? maxNWastedAttempts : 0,
                                        delay: initialDelay,
                                        logger: logger
                                    ).query
                                )

                            // if query.text.starts(with: "ERROR:") {
                            //     throw QueryGenerationError.cannotGenerateQuery(comment: query.text)
                            // }
                            // print("\(index)th query*:")
                            // print(query.text)
                            
                            try QueryGenerationError.fromGeneratedQuery(query: query)

                            return try await adapter.sample(
                                query,
                                timeout: item.limit == 1 ? maxTimeout : timeout,
                                maxNWastedAttempts: item.limit == 1 ? maxNWastedAttempts : 0,
                                delay: initialDelay,
                                logger: logger
                            )
                        } handleExecutionTimeMeasurement: { (sample, executionTime) -> Sample<BindingType> in 
                            logger.trace(
                                "Processed \(index)th query batch using query generator (limit = \(item.limit), offset = \(item.offset), n-bindings = \(sample.nBindings), evaluation-time = \(executionTime) seconds, " + // ") for " +
                                "count = \(sample.count)) for " +
                                ((kind ?? .positive) == .negative ? "negative " : "") +
                                "pattern \(pattern ?? "")"
                            )
                            return sample
                        }
                    } catch {
                        logger.trace("Failed \(index)th query: \(error)")

                        switch error {
                            case QueryGenerationError.stopIteration:
                                throw TaskExecitionError.stopIteration(item: item, index: index, workerIndex: workerIndex, reason: error, retry: false)
                            case QueryGenerationError.cannotGenerateQuery:
                                throw TaskExecitionError.taskHasFailed(item: item, index: index, workerIndex: workerIndex, reason: error, retry: false)
                            default:
                                throw TaskExecitionError.taskHasFailed(item: item, index: index, workerIndex: workerIndex, reason: error, retry: true)
                        }
                    }
                // } until: { sample, index in
                //     await terminationManager.shouldStop(receivedStopIndicator: sample.nBindings == 0, index: index)
                //     // sample.nBindings == 0
                } truncateElement: { item, index in
                    if item.limit % 2 != 0 {
                        throw WorkloadDistributionError.cannotDistributeWorkloadEvenly(item: item, index: index)
                    }

                    return [(item: (limit: item.limit / 2, offset: item.offset), index: index + [0]), (item: (limit: item.limit / 2, offset: item.offset + item.limit / 2), index: index + [1])]
                }

                return try join(samples)
            } else if query.containsPatternPlaceHolders {
                var batchIterator = BatchIterator(limit: batchSizeUnwrapped)
                let terminationManager = TerminationManager()

                let samples = try await batchIterator.asyncDo(nWorkers: nWorkers) { (item, workerIndex, index) -> Sample<BindingType> in
                    logger.trace("Processing query for pattern: \(pattern)")
                    do {
                        return try await measureExecutionTime { () -> Sample<BindingType> in
                            let query: CountingQueryWithAggregation<BindingType> = getQuery(query, limit: item.limit, offset: item.offset)
                            // print("\(index)th query: ")
                            // print(query.text)
                            return try await adapter.sample(
                                query,
                                timeout: item.limit == 1 ? maxTimeout : timeout,
                                maxNWastedAttempts: item.limit == 1 ? maxNWastedAttempts : 0,
                                delay: initialDelay,
                                logger: logger
                            )
                        } handleExecutionTimeMeasurement: { (sample, executionTime) -> Sample<BindingType> in 
                            logger.trace(
                                "Processed \(index)th query batch (limit = \(item.limit), offset = \(item.offset), n-bindings = \(sample.nBindings), evaluation-time = \(executionTime) seconds, " + 
                                "count = \(sample.count)) for " +
                                ((kind ?? .positive) == .negative ? "negative " : "") +
                                "pattern \(pattern ?? "")"
                            )
                            return sample
                        }
                    } catch {
                        logger.trace("Failed \(index)th query: \(error)")
                        throw TaskExecitionError.taskHasFailed(item: item, index: index, workerIndex: workerIndex, reason: error, retry: true)
                    }
                } until: { sample, index in
                    await terminationManager.shouldStop(receivedStopIndicator: sample.nBindings == 0, index: index)
                    // sample.nBindings == 0
                } truncateElement: { item, index in
                    if item.limit % 2 != 0 {
                        throw WorkloadDistributionError.cannotDistributeWorkloadEvenly(item: item, index: index)
                    }

                    return [(item: (limit: item.limit / 2, offset: item.offset), index: index + [0]), (item: (limit: item.limit / 2, offset: item.offset + item.limit / 2), index: index + [1])]

                    // [(item: item, index: index)]
                }

                return try join(samples)
            }
        }

        // print("WTD")

        // return try await adapter.sample(
        //     getQuery(query),
        //     timeout: timeout
        // )

        return try await measureExecutionTime { () -> Sample<BindingType> in
            try await adapter.sample(
                getQuery(query),
                timeout: maxTimeout, // timeout,
                maxNWastedAttempts: 1, // maxNWastedAttempts,
                delay: initialDelay,
                logger: logger
            )
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
        // print("Negative query generaor = \(String(describing: negativeQueryGenerator?.getText(name: name)))")
        return try await measureExecutionTime {
            (
                positive: try await getSample(
                    adapter, query: positiveQueryText.getText(name: name), timeout: timeout, logger: logger, pattern: pattern,
                    kind: .positive, nWorkers: nWorkers, queryGenerator: positiveQueryGenerator?.getText(name: name)
                ),
                negative: try await getSample(
                    adapter, query: negativeQueryText.getText(name: name), timeout: timeout, logger: logger, pattern: pattern,
                    kind: .negative, nWorkers: nWorkers, queryGenerator: negativeQueryGenerator?.getText(name: name)
                ),
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

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        elements = try values.decode([Pattern].self, forKey: .elements).filter{$0.enabled ?? true}
    }

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

