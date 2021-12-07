import Foundation
import ArgumentParser
import Logging
import wickedData

public enum Dataset: String {
    case demo, wordnet_11, wordnet_18, wordnet_18_rr, fb_13, fb_15k
}

public struct DatasetImpl: CustomStringConvertible {
    public let name: Dataset
    public let path: String

    public var description: String {
        "\(name)@\(path)"
    }
}

let DATASETS_FOR_COMPARISON: [DatasetImpl] = [
<<<<<<< HEAD
    // ModelImpl(architecture: .se, platform: .grapex),
    // ModelImpl(architecture: .transe, platform: .grapex),
    // DatasetImpl(name: .demo, path: "Demo/0000"),
    DatasetImpl(name: .wordnet_11, path: "wordnet-11"),
    // ModelImpl(architecture: .complex, platform: .openke)
=======
    // DatasetImpl(name: .demo, path: "Demo/0000"),
    // DatasetImpl(name: .wordnet_11, path: "wordnet-11"),
    // DatasetImpl(name: .wordnet_18, path: "wordnet-18"),
    // DatasetImpl(name: .wordnet_18_rr, path: "wordnet-18-rr"),
    // DatasetImpl(name: .fb_13, path: "fb-13"),
    DatasetImpl(name: .fb_15k, path: "fb-15k"),
>>>>>>> origin/master
]

public struct PatternProcessingResult: Sendable {
    public let cellValues: [[CellValue]]
    public let description: String
    let asDict: DatasetTestingResult

    public init<BindingType>(_ stats: PatternStats<BindingType>, pattern: String) {
        cellValues = [
            [CellValue.string(value: pattern)] + stats.descriptionItems
        ]
        description = "\(pattern)\t\(stats)"
        asDict = stats.asDict
    }
}

public enum PatternError: Error {
    case unsupportedPattern(name: String)
}

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

    @Flag(name: .long, help: "Skip database update operations (this flag should be used only for test purposes when a dataset is repeatedly uploaded to the knowledge base)")
    var doNotUpdate = false

    @Flag(name: .long, help: "Print request body instead of exporing comparison results")
    var dryRun = false

    @Option(name: .long, help: "Maximum number of patterns which are allowed to be processed concurrently in separate processes")
    var nPatternProcessingWorkers: Int?

    @Option(name: .long, help: "Maximum number of dataset upload operations which are allowed to run in parallel")
    var nDatasetUploadingWorkers: Int?

    @Option(name: .shortAndLong, help: "Maximum number of milliseconds which can be spent on analyzis of a single pattern")
    var samplingTimeout: Int?

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

        let nPatternProcessingWorkers_ = nPatternProcessingWorkers
        let nDatasetUploadingWorkers_ = nDatasetUploadingWorkers

        let verbose_ = verbose
        let doNotUpdate_ = doNotUpdate
        let samplingTimeout_ = samplingTimeout

        // print(OpenKEImporter(unwrappedCorpus, batches: batches).asTtls(batchSize: 5).first!)
        BlockingTask {
            let adapter = BlazegraphAdapter(address: blazegraphHost_)
            let patterns = Patterns(patternsPath_)

            let tracker = DatasetComparisonProgressTracker(nDatasets: DATASETS_FOR_COMPARISON.count, nPatterns: patterns.storage.elements.count)
            let telegramBot = try! TelegramAdapter(
                tracker: tracker,
                secret: ProcessInfo.processInfo.environment["EMBEDDABOT_SECRET"],
                logger: Logger(level: verbose_ ? .trace : .info, label: "telegram-bot")
            )

            let googleSheetsAdapter = exportToGoogleSheets_ ? try? GoogleSheetsApiAdapter(telegramBot: telegramBot) : nil

            var currentMetricsRowOffset = 0
            var nPatterns = 0
            var datasetTestingResults = [DatasetTestingResult]()

            async let void: () = await telegramBot.run()
            
            Task {
                telegramBot.broadcast("The bot has started")
            }

            // func appendStatCells<BindingType>(_ stats: PatternStats<BindingType>, pattern: String) throws {
            //     if let unwrappedAdapter = googleSheetsAdapter {
            //         _ = try unwrappedAdapter.appendCells(
            //             [
            //                 [CellValue.string(value: pattern)] + stats.descriptionItems
            //             ]
            //         )
            //         currentMetricsRowOffset += 1
            //         nPatterns += 1
            //     }
            // }

            func appendStatCells(_ patternProcessingResult: PatternProcessingResult) throws {
                if let unwrappedAdapter = googleSheetsAdapter {
                    _ = try unwrappedAdapter.appendCells(
                        patternProcessingResult.cellValues
                    )
                    currentMetricsRowOffset += 1
                    nPatterns += 1
                }
                datasetTestingResults.append(patternProcessingResult.asDict)
                logger.info(Logger.Message(stringLiteral: patternProcessingResult.description))
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
            var optimalValueLocations = [CellLocation]()

            currentMetricsRowOffset += 6

            for dataset in DATASETS_FOR_COMPARISON {

                Task {
                    telegramBot.broadcast("Evaluating dataset \(dataset) on \(patterns.storage.elements.count) patterns...")
                }

                nPatterns = 0
                logger.info("Evaluating dataset \(dataset.name)...")
                
                if !doNotUpdate_ {
                    logger.info("Cleaning the knowledge base...")
                    let clearResponse = try! await adapter.clear()
                    datasetTestingResults = [DatasetTestingResult]()
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
                        let ttls = OpenKEImporter(dataset.path, batches: batches, logger: logger).asTtls(batchSize: unwrappedBatchSize)
                        logger.trace("Generated \(ttls.count) batches for updating the knowledge base")
                        // for i in 0..<ttls.count {
                        _ = try! await (0..<ttls.count).asyncMap(nWorkers: nDatasetUploadingWorkers_) { i, _ -> Bool in
                            logger.trace("Inserting \(i + 1) batch...")
                            let insertResponse = try! await adapter.insert( 
                                InsertQuery(
                                    text: ttls[i]
                                ) // ,
                                // timeout: 3_600_000
                            )
                            logger.trace(Logger.Message(stringLiteral: String(describing: insertResponse)))

                            return true
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

                    Task {
                        telegramBot.broadcast("Uploaded \(dataset) to the knowledge base")
                    }
                } else {
                    logger.info("Skipping dataset uplaoding to the knowledge base...")

                    Task {
                        telegramBot.broadcast("Skipped \(dataset) uploading to the knowledge base")
                    }
                }

                logger.info("pattern\t\(PatternStats<CountableBindingTypeWithOneRelationAggregation>.header)")

                _ = try! googleSheetsAdapter?.appendCells(
                    [
                        [CellValue.string(value: "pattern")] + PatternStats<CountableBindingTypeWithOneRelationAggregation>.headerItems
                    ]
                )
                currentMetricsRowOffset += 1

                // Task {
                //     await tracker.setNpatterns(.storage.sets.count)
                // }

                // for pattern in patterns.storage.elements {
                _ = try! await patterns.storage.elements.asyncMap(nWorkers: nPatternProcessingWorkers_) { pattern, _ -> PatternProcessingResult in
                    defer {
                        Task {
                            await tracker.nextPattern()
                        }
                    }
                    switch pattern.name {
                        case "symmetric":
                            let stats: PatternStats<CountableBindingTypeWithOneRelationAggregation> = try! await pattern.evaluate(adapter, timeout: samplingTimeout_) 
                            return PatternProcessingResult(stats, pattern:"symmetric") // , logger: logger)
                            // try! appendStatCells(stats, pattern: "symmetric")
                            // datasetTestingResults.append(stats.asDict)
                            // logger.info("symmetric\t\(stats)")
                        case "antisymmetric":
                            let stats: PatternStats<CountableBindingTypeWithAntisymmetricRelationsAggregation> = try! await pattern.evaluate(adapter, timeout: samplingTimeout_) 
                            return PatternProcessingResult(stats, pattern:"antisymmetric") // , logger: logger)
                            // try! appendStatCells(stats, pattern: "antisymmetric")
                            // datasetTestingResults.append(stats.asDict)
                            // logger.info("antisymmetric\t\(stats)")
                        case "equivalence":
                            let stats: PatternStats<CountableBindingTypeWithEquivalentRelationsAggregation> = try! await pattern.evaluate(adapter, timeout: samplingTimeout_) 
                            return PatternProcessingResult(stats, pattern:"equivalence") // , logger: logger)
                            // try! appendStatCells(stats, pattern: "equivalence")
                            // datasetTestingResults.append(stats.asDict)
                            // logger.info("equivalence\t\(stats)")
                        case "implication":
                            let stats: PatternStats<CountableBindingTypeWithImplicationRelationsAggregation> = try! await pattern.evaluate(adapter, timeout: samplingTimeout_) 
                            return PatternProcessingResult(stats, pattern:"implication") // , logger: logger)
                            // try! appendStatCells(stats, pattern: "implication")
                            // datasetTestingResults.append(stats.asDict)
                            // logger.info("implication\t\(stats)")
                        case "reflexive":
                            let stats: PatternStats<CountableBindingTypeWithReflexiveRelationAggregation> = try! await pattern.evaluate(adapter, timeout: samplingTimeout_) 
                            return PatternProcessingResult(stats, pattern:"reflexive") // , logger: logger)
                            // try! appendStatCells(stats, pattern: "reflexive")
                            // datasetTestingResults.append(stats.asDict)
                            // logger.info("reflexive\t\(stats)")
                        case "transitive":
                            let stats: PatternStats<CountableBindingTypeWithTransitiveRelationAggregation> = try! await pattern.evaluate(adapter, timeout: samplingTimeout_) 
                            return PatternProcessingResult(stats, pattern:"transitive") // , logger: logger)
                            // try! appendStatCells(stats, pattern: "transitive")
                            // datasetTestingResults.append(stats.asDict)
                            // logger.info("transitive\t\(stats)")
                        case "composition":
                            let stats: PatternStats<CountableBindingTypeWithCompositionRelationsAggregation> = try! await pattern.evaluate(adapter, timeout: samplingTimeout_) 
                            return PatternProcessingResult(stats, pattern:"composition") // , logger: logger)
                            // try! appendStatCells(stats, pattern: "composition")
                            // datasetTestingResults.append(stats.asDict)
                            // logger.info("composition\t\(stats)")
                        case let patternName:
                            throw PatternError.unsupportedPattern(name: patternName)
                            // print("Unsupported pattern \(patternName)") 
                    }
                }.map(appendStatCells)

                Task {
                    telegramBot.broadcast("Finished \(dataset) evaluation")
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

                optimalValueLocations.append(contentsOf: datasetTestingResults.getOptimalValueLocations(offset: CellLocation(row: currentMetricsRowOffset - nPatterns, column: 1)))

                currentMetricsRowOffset += 1

                Task {
                    await tracker.nextDataset()
                }

                _ = await tracker.resetNprocessedPatterns()
            }

            if let unwrappedAdapter = googleSheetsAdapter { // TODO: Make one call for all datasets
                _ = unwrappedAdapter.emphasizeCells(
                    optimalValueLocations,
                    sheet: unwrappedAdapter.lastSheetId
                )
            }

            _ = googleSheetsAdapter?.addNumberFormatRules(numberFormatRanges!.numberFormatRules)
            _ = try! await googleSheetsAdapter?.commit(dryRun: dryRun_)

            telegramBot.broadcast("Completed comparing datasets")
        } // BlockingTask
    }
}

