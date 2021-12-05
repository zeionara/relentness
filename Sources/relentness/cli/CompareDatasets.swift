import Foundation
import ArgumentParser
import Logging
import wickedData

public enum Dataset: String {
    case demo, wordnet_11
}

public struct DatasetImpl: CustomStringConvertible {
    public let name: Dataset
    public let path: String

    public var description: String {
        "\(name)@\(path)"
    }
}

let DATASETS_FOR_COMPARISON: [DatasetImpl] = [
    // ModelImpl(architecture: .se, platform: .grapex),
    // ModelImpl(architecture: .transe, platform: .grapex),
    DatasetImpl(name: .demo, path: "Demo/0000"),
    DatasetImpl(name: .wordnet_11, path: "wordnet-11"),
    // ModelImpl(architecture: .complex, platform: .openke)
]

public struct CompareDatasets: ParsableCommand {
    // @Argument(help: "Path to the directory with dataset files")
    // var corpus: String?

    @Flag(name: .shortAndLong, help: "Enable wordy way of logging")
    var verbose = false

    @Flag(name: .long, help: "Enably wordy way of logging")
    var discardExistingLogFile = false

    @Option(name: .shortAndLong, help: "Name of log file")
    var logFileName: String?

    @Option(name: .shortAndLong, help: "Name of file with patten definitions")
    var patternsPath: String

    @Option(name: .long, help: "Ip address of the running blazegraph server")
    var blazegraphHost: String

    @Option(name: .shortAndLong, help: "Number of statements per query for updating the knowledge base")
    var batchSize: Int?

    @Flag(name: .long, help: "Include triples from the test batch into the evaluation process")
    var testSubset = false

    @Flag(name: .long, help: "Include triples from the validation batch into the evaluation process")
    var validationSubset = false

    @Flag(name: .long, help: "Write results to google sheets")
    var exportToGoogleSheets = false

    @Flag(name: .long, help: "Print request body instead of exporing comparison results")
    var dryRun = false

    public static var configuration = CommandConfiguration(
        commandName: "compare-datasets",
        abstract: "Evaluate datasets by checking which graph patterns are present in their structure"
    )

    public init() {}


    mutating public func run() {

        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  
        let logger = Logger(level: verbose ? .trace : .info, label: "main")
        logger.trace("Executing command \(CommandLine.arguments.joined(separator: " "))...")

        let blazegraphHost_ = blazegraphHost
        
        // if let unwrappedCorpus = corpus {
        var batches = ["train2id"]

        if testSubset {
            batches.append("test2id")
        }

        if validationSubset {
            batches.append("valid2id")
        }

        let batchSize_ = batchSize
        let patternsPath_ = patternsPath
        let exportToGoogleSheets_ = exportToGoogleSheets
        let dryRun_ = dryRun

        // print(OpenKEImporter(unwrappedCorpus, batches: batches).asTtls(batchSize: 5).first!)
        BlockingTask {
            let adapter = BlazegraphAdapter(address: blazegraphHost_)
            let patterns = Patterns(patternsPath_)

            let googleSheetsAdapter = exportToGoogleSheets_ ? try? GoogleSheetsApiAdapter(telegramBot: nil) : nil
            var currentMetricsRowOffset = 0
            var nPatterns = 0

            func appendStatCells<BindingType>(_ stats: PatternStats<BindingType>, pattern: String) throws {
                if let unwrappedAdapter = googleSheetsAdapter {
                    _ = try unwrappedAdapter.appendCells(
                        [
                            [CellValue.string(value: pattern)] + stats.descriptionItems
                        ]
                    )
                    currentMetricsRowOffset += 1
                    nPatterns += 1
                }
            }

            _ = try! googleSheetsAdapter?
                .addSheet(tabColor: "e67c73") // soft red
                .appendCells(
                    [
                        [
                            CellValue.string(value: "OS:"), CellValue.string(value: try! runScriptAndGetOutput("print-os-version")!)
                        ],
                        [
                            CellValue.string(value: "CPU:"), CellValue.string(value: try! runScriptAndGetOutput("print-cpu-info")!)
                        ],
                        [
                            CellValue.string(value: "RAM:"), CellValue.string(value: try! runScriptAndGetOutput("print-ram-info")!)
                        ],
                        [
                            CellValue.string(value: "GPU:"), CellValue.string(value: try! runScriptAndGetOutput("print-gpu-info")!)
                        ],
                        [
                            CellValue.string(value: "Command:"), CellValue.string(value: CommandLine.arguments.joined(separator: " "))
                        ],
                        [
                            CellValue.string(value: "")
                        ]
                    ],
                    format: .bold
                )

            let numberFormatRanges = googleSheetsAdapter == nil ? nil : DatasetCompatisonNumberFormatRanges(sheet: googleSheetsAdapter!.lastSheetId)

            currentMetricsRowOffset += 6

            for dataset in DATASETS_FOR_COMPARISON {
                nPatterns = 0
                logger.info("Evaluating dataset \(dataset.name)...")
                logger.info("Cleaning the knowledge base...")
                let clearResponse = try! await adapter.clear()
                logger.trace(Logger.Message(stringLiteral: String(describing: clearResponse)))
                logger.info("Filling the knowledge base with required data...")

                _ = try! googleSheetsAdapter?.appendCells(
                    [
                        [
                            CellValue.string(value: "Evaluating dataset \(dataset)...")
                        ]
                    ],
                    format: .bold
                )
                currentMetricsRowOffset += 1

                // OpenKEImporter(unwrappedCorpus, batches: batches).toTtl()
                if let unwrappedBatchSize = batchSize_ {
                    let ttls = OpenKEImporter(dataset.path, batches: batches).asTtls(batchSize: unwrappedBatchSize)
                    logger.trace("Generated \(ttls.count) batches for updating the knowledge base")
                    for i in 0..<ttls.count {
                        logger.trace("Inserting \(i + 1) batch...")
                        let insertResponse = try! await adapter.insert( 
                            InsertQuery(
                                text: ttls[i]
                            ) // ,
                            // timeout: 3_600_000
                        )
                        logger.trace(Logger.Message(stringLiteral: String(describing: insertResponse)))
                    }
                    logger.trace("Finished knowledge base update")
                } else {
                    let insertResponse = try! await adapter.insert(
                        InsertQuery(
                            text: OpenKEImporter(dataset.path, batches: batches).asTtl
                        ),
                        timeout: 3_600_000
                    )
                    logger.trace(Logger.Message(stringLiteral: String(describing: insertResponse)))
                }
            // }


        // }

        // BlockingTask {
            // let countSymmetricPairs = CountingQuery(
            //     text: """
            //     select (count(?h) as ?count) where {
            //       ?h ?r ?t.
            //       ?t ?r ?h
            //     }
            //     """
            // )

            // let countAsymmetricTriples = CountingQuery(
            //     text: """
            //     select (count(?h) as ?count) where {
            //       ?h ?r ?t.
            //       filter ( !exists { ?t ?r ?h } )
            //     }
            //     """
            // )

            // let adapter = BlazegraphAdapter(address: blazegraphHost_)

            // let nSymmetricTriples = try! await adapter.sample(countSymmetricPairs).count
            // let nAsymmetricTriples = try! await adapter.sample(countAsymmetricTriples).count
            // let nTotalTriples = nSymmetricTriples + nAsymmetricTriples

            // print("\(String(format: "%.3f", Double(nSymmetricTriples) / Double(nTotalTriples))) portion of triples are symmetrical") 

            // print("Handling patterns...")

                logger.info("pattern\t\(PatternStats<CountableBindingTypeWithOneRelationAggregation>.header)")

                _ = try! googleSheetsAdapter?.appendCells(
                    [
                        [CellValue.string(value: "pattern")] + PatternStats<CountableBindingTypeWithOneRelationAggregation>.headerItems
                    ]
                )
                currentMetricsRowOffset += 1

                var datasetTestingResults = [DatasetTestingResult]()

                for pattern in patterns.storage.elements {
                    switch pattern.name {
                        case "symmetric":
                            let stats: PatternStats<CountableBindingTypeWithOneRelationAggregation> = try! await pattern.evaluate(adapter) 
                            try! appendStatCells(stats, pattern: "symmetric")
                            datasetTestingResults.append(stats.asDict)
                            logger.info("symmetric\t\(stats)")
                        case "antisymmetric":
                            let stats: PatternStats<CountableBindingTypeWithAntisymmetricRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            try! appendStatCells(stats, pattern: "antisymmetric")
                            datasetTestingResults.append(stats.asDict)
                            logger.info("antisymmetric\t\(stats)")
                        case "equivalence":
                            let stats: PatternStats<CountableBindingTypeWithEquivalentRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            try! appendStatCells(stats, pattern: "equivalence")
                            datasetTestingResults.append(stats.asDict)
                            logger.info("equivalence\t\(stats)")
                        case "implication":
                            let stats: PatternStats<CountableBindingTypeWithImplicationRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            try! appendStatCells(stats, pattern: "implication")
                            datasetTestingResults.append(stats.asDict)
                            logger.info("implication\t\(stats)")
                        case "reflexive":
                            let stats: PatternStats<CountableBindingTypeWithReflexiveRelationAggregation> = try! await pattern.evaluate(adapter) 
                            try! appendStatCells(stats, pattern: "reflexive")
                            datasetTestingResults.append(stats.asDict)
                            logger.info("reflexive\t\(stats)")
                        case "transitive":
                            let stats: PatternStats<CountableBindingTypeWithTransitiveRelationAggregation> = try! await pattern.evaluate(adapter) 
                            try! appendStatCells(stats, pattern: "transitive")
                            datasetTestingResults.append(stats.asDict)
                            logger.info("transitive\t\(stats)")
                        case "composition":
                            let stats: PatternStats<CountableBindingTypeWithCompositionRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            try! appendStatCells(stats, pattern: "composition")
                            datasetTestingResults.append(stats.asDict)
                            logger.info("composition\t\(stats)")
                        case let patternName:
                            print("Unsupported pattern \(patternName)") 
                    }
                }

                _ = try! googleSheetsAdapter?.appendCells( // Empty line for visual separation of adjacent dataset testing results
                    [
                        [CellValue.string(value: "")]
                    ]
                )

                // let offset = CellLocation(row: currentMetricsRowOffset, column: 1)
                _ = googleSheetsAdapter?.addConditionalFormatRules(
                    [
                        ConditionalFormatRule(
                            range: Range(
                                length: 2,
                                height: nPatterns,
                                offset: CellLocation(
                                    row: currentMetricsRowOffset - nPatterns,
                                    column: 1
                                ),
                                sheet: googleSheetsAdapter!.lastSheetId
                            )
                        ),
                        ConditionalFormatRule(
                            range: Range(
                                length: 2,
                                height: nPatterns,
                                offset: CellLocation(
                                    row: currentMetricsRowOffset - nPatterns,
                                    column: 3
                                ),
                                sheet: googleSheetsAdapter!.lastSheetId
                            )
                        ),
                        ConditionalFormatRule(
                            range: Range(
                                length: 1,
                                height: nPatterns,
                                offset: CellLocation(
                                    row: currentMetricsRowOffset - nPatterns,
                                    column: 5
                                ),
                                sheet: googleSheetsAdapter!.lastSheetId
                            )
                        ),
                        ConditionalFormatRule(
                            range: Range(
                                length: 2,
                                height: nPatterns,
                                offset: CellLocation(
                                    row: currentMetricsRowOffset - nPatterns,
                                    column: 6
                                ),
                                sheet: googleSheetsAdapter!.lastSheetId
                            )
                        ),
                        ConditionalFormatRule(
                            range: Range(
                                length: 1,
                                height: nPatterns,
                                offset: CellLocation(
                                    row: currentMetricsRowOffset - nPatterns,
                                    column: 8
                                ),
                                sheet: googleSheetsAdapter!.lastSheetId
                            )
                        ),
                        ConditionalFormatRule(
                            range: Range(
                                length: 1,
                                height: nPatterns,
                                offset: CellLocation(
                                    row: currentMetricsRowOffset - nPatterns,
                                    column: 9
                                ),
                                sheet: googleSheetsAdapter!.lastSheetId
                            ),
                            inverse: true
                        )
                    ]
                )

                numberFormatRanges?.addMeasurements(height: nPatterns, offset: CellLocation(row: currentMetricsRowOffset - nPatterns, column: 1))

                if let unwrappedAdapter = googleSheetsAdapter { // TODO: Make one call for all datasets
                    _ = unwrappedAdapter.emphasizeCells(
                        datasetTestingResults.getOptimalValueLocations(offset: CellLocation(row: currentMetricsRowOffset - nPatterns, column: 1)),
                        sheet: unwrappedAdapter.lastSheetId
                    )
                }

                currentMetricsRowOffset += 1
            }
            // print("There are \(try! await adapter.sample(countSymmetricPairs).count) symmetric relation pair instances in the knowledge base")

            _ = googleSheetsAdapter?.addNumberFormatRules(numberFormatRanges!.numberFormatRules)
            _ = try! await googleSheetsAdapter?.commit(dryRun: dryRun_)
        } // BlockingTask
    }
}

