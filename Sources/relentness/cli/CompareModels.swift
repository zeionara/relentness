import Foundation
import ArgumentParser
import Logging
import wickedData
import ahsheet

let MODELS_FOR_COMPARISON: [ModelImpl] = [
    // ModelImpl(architecture: .se, platform: .grapex),
    // ModelImpl(architecture: .transe, platform: .grapex),
    ModelImpl(architecture: .transe, platform: .openke),
    ModelImpl(architecture: .complex, platform: .openke)
]

public typealias ModelTestingResult = (meanMetrics: MeagerMetricSeries, hparams: HyperParamSet, executionTime: Double) // TODO: Change MeagerMetricSeries to an abstract MetricSeries data type

public enum ComparisonException: Error {
    case invalidModel(model: ModelImpl, message: String? = nil)
}

public struct CompareModels: ParsableCommand {
    @Argument(help: "Name of folder which keeps the dataset for testing")
    var corpus: String

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"

    @Option(help: "Path to the cloned repository with the grapex framework with respect to the home directory for current user")
    var grapexRoot: String = "grapex"

    @Option(name: .shortAndLong, help: "Maximum number of concurrently running tests")
    var nWorkers: Int?

    @Option(name: .shortAndLong, help: "Path to yaml file with hyperparams")
    var path: String

    @Argument(help: "Seeds to use during testing")
    var seeds: [Int] = [Int]() // [17, 2000]

    @Flag(name: .shortAndLong, help: "Delete trained model files")
    var remove = false

    @Flag(name: .shortAndLong, help: "Enable gpu")
    var gpu = false

    @Flag(name: .shortAndLong, help: "Run each worker on different gpu")
    var differentGpus = false

    @Flag(name: .shortAndLong, help: "Enably wordy way of logging")
    var verbose = false

    @Flag(name: .long, help: "Write results to google sheets")
    var exportToGoogleSheets = false

    @Flag(name: .long, help: "Enably wordy way of logging")
    var discardExistingLogFile = false

    @Option(name: .shortAndLong, help: "Name of log file")
    var logFileName: String?

    @Option(name: .long, help: "Delay to wait for before running consecutive tests (in seconds)")
    var delay: Double?

    @Option(name: .long, help: "Delay to wait before killing a running model testing process and trying again (in seconds)")
    var terminationDelay: Double?

    @Flag(name: .long, help: "Print request body instead of exporing comparison results")
    var dryRun = false

    @Flag(name: .long, help: "Should send notifications via telegram when progress is updated")
    var enableNotifications = false

    public static var configuration = CommandConfiguration(
        commandName: "compare-models",
        abstract: "Compare knowledge graph embedding models by selecting optimal set of hyperparams and performing validation"
    )

    public init() {}

    mutating public func run() {
        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  

        let logger = Logger(level: verbose ? .trace : .info, label: "main")
        
        logger.trace("Executing command \(CommandLine.arguments.joined(separator: " "))...")

        let exportToGoogleSheets_ = exportToGoogleSheets
        let enableNotifications_ = enableNotifications

        let env_ = env
        let grapexRoot_ = grapexRoot
        let corpus_ = corpus

        let nWorkers_ = nWorkers
        let seeds_ = seeds

        let remove_ = remove
        let gpu_ = gpu
        let differentGpus_ = differentGpus

        let path_ = path
        let delay_ = delay
        let terminationDelay_ = terminationDelay

        let dryRun_ = dryRun

        let verbose_ = verbose

        BlockingTask {
            let tracker = ModelComparisonProgressTracker(nModels: MODELS_FOR_COMPARISON.count, nHyperParameterSets: 0)
            let telegramBot = enableNotifications_ ? try! TelegramAdapter(
                tracker: tracker,
                secret: ProcessInfo.processInfo.environment["EMBEDDABOT_SECRET"],
                logger: Logger(level: verbose_ ? .trace : .info, label: "telegram-bot")
            ) : nil

            async let void = await telegramBot?.run()

            Task {
                telegramBot?.broadcast("The bot has started")
            }

            let adapter = exportToGoogleSheets_ ? try? GoogleSheetsApiAdapter(telegramBot: telegramBot) : nil

            // print("foo")

            var currentMetricsRowOffset = 0
            let formatRanges = adapter == nil ? nil : MeagerMetricSetFormatRanges(sheet: adapter!.lastSheetId + 1)  
            let numberFormatRanges = adapter == nil ? nil : MeagerMetricSetNumberFormatRanges(sheet: adapter!.lastSheetId + 1)

            _ = try! adapter?
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

            currentMetricsRowOffset += 6

            var hparams = [String: HyperParamSet]()
            let nTunableHparams = HyperParamSet.headerItems.count

            for model in MODELS_FOR_COMPARISON {
                logger.info("Testing model \(model)...")
                logger.info("\(HyperParamSet.header)\t\(MeagerMetricSeries.headerWithExecutionTime)")

                _ = try! adapter?.appendCells(
                    [
                        [
                            CellValue.string(value: "Testing model \(model)...")
                        ]
                    ],
                    format: .bold
                ).appendCells(
                    [
                        HyperParamSet.headerItems + MeagerMetricSeries.headerItemsWithExecutionTime
                    ]
                )

                currentMetricsRowOffset += 2

                let sets = try! HyperParamSets(corpus_, model.architecture.rawValue, path_)
                var collectedModelTestingResults = [ModelTestingResult]()

                telegramBot?.broadcast("Testing model \(model) on \(sets.storage.sets.count) hyperparameter sets...")

                // if !startedTelegramBot {
                //     print("Starting telegram bot...")
                //     tracker = ProgressTracker(nModels: MODELS_FOR_COMPARISON.count, nHyperParameterSets: sets.storage.sets.count)
                //     telegramBot = try? TelegramAdapter(tracker: tracker!)


                //     startedTelegramBot = true

                //     print("Exiting...")
                // } else {
                //     if let unwrappedTracker = tracker {
                //         async let result = unwrappedTracker.nextModel(nHyperParameterSets: sets.storage.sets.count)
                //     }
                // }

                // if let unwrappedBot = telegramBot {
                //     async let botCompletionResult = unwrappedBot.run()
                //     print("Started")
                // }

                // if isFirstModel {
                Task {
                    await tracker.setNhyperParameterSets(sets.storage.sets.count)
                }

                logger.trace("Add measurements for the conditional format ranges")

                formatRanges?.addMeasurements(
                    height: sets.storage.sets.count,
                    offset: CellLocation(
                        row: currentMetricsRowOffset,
                        column: nTunableHparams
                    )
                )

                logger.trace("Add measurements for the numerical format ranges")

                numberFormatRanges?.addMeasurements(
                    height: sets.storage.sets.count,
                    offset: CellLocation(
                        row: currentMetricsRowOffset,
                        column: nTunableHparams
                    )
                )

                logger.trace("Checking hyperparams...")

                for hparams in sets.storage.sets {
                    do {
                        let (metrics, executionTime) = try await traceExecutionTime(logger) { () -> [[OpenKeTester.Metrics]] in
                            switch model.platform {
                            case .openke:
                                throw NotImplementedError.platformIsNotSupported(name: "openke")
                                // return try await OpenKeTester(
                                //     model: model.architecture.asOpenKeModel,
                                //     env: env_,
                                //     corpus: corpus_,
                                //     nWorkers: nWorkers_,
                                //     remove: remove_,
                                //     gpu: gpu_,
                                //     differentGpus: differentGpus_,
                                //     terminationDelay: terminationDelay_,
                                //     logger: logger
                                // ).run(
                                //     seeds: seeds_.count > 0 ? seeds_ : nil,
                                //     delay: delay_,
                                //     hparams: hparams
                                // )
                            case .grapex:
                                throw NotImplementedError.platformIsNotSupported(name: "grapex")
                                // return try await GrapexTester(
                                //     model: model.architecture.asGrapexModel,
                                //     env: grapexRoot_,
                                //     corpus: corpus_,
                                //     nWorkers: nWorkers_,
                                //     remove: remove_,
                                //     gpu: gpu_,
                                //     differentGpus: differentGpus_,
                                //     terminationDelay: terminationDelay_
                                // ).run(
                                //     seeds: seeds_.count > 0 ? seeds_ : nil,
                                //     delay: delay_,
                                //     hparams: hparams
                                // )
                            }
                        }

                        let meanMetrics = mean(sets: metrics).mean.mean.mean
                        collectedModelTestingResults.append((meanMetrics: meanMetrics, hparams: hparams, executionTime: executionTime))

                        logger.info("\(hparams)\t\(meanMetrics.descriptionWithExecutionTime(executionTime))") // Firstly average by cv-splits, then by seeds, then by filters and finally by corruption strategy

                        _ = try! adapter?.appendCells(
                            [
                                hparams.descriptionItems + meanMetrics.descriptionItemsWithExecutionTime(executionTime)
                            ]
                        )
                    } catch let error {
                        logger.error("Unexpected error \(error), cannot complete testing")
                        return
                        // throw error
                    }

                    // if let unwrappedTracker = tracker {
                    //     async let result = unwrappedTracker.nextHyperParameterSet()
                    // }
                    Task {
                        await tracker.nextHyperParameterSet()
                    }
                }

                let bestHparams = collectedModelTestingResults.sorted{ (lhs, rhs) in
                    lhs.meanMetrics.weightedSum(executionTime: lhs.executionTime) > rhs.meanMetrics.weightedSum(executionTime: rhs.executionTime)
                }.first!.hparams

                if let unwrappedAdapter = adapter {
                    _ = unwrappedAdapter.emphasizeCells(
                        collectedModelTestingResults.getOptimalValueLocations(offset: CellLocation(row: currentMetricsRowOffset, column: nTunableHparams)),
                        sheet: unwrappedAdapter.lastSheetId
                    )
                }

                logger.info("Best hyperparameter values: ")
                logger.info("\(String(describing: HyperParamSet.header))")
                logger.info("\(String(describing: bestHparams))")
                logger.info("")

                _ = try! adapter?.appendCells(
                    [
                        [
                            CellValue.string(value: "Best hyperparameter values:")
                        ],
                        HyperParamSet.headerItems,
                        bestHparams.descriptionItems,
                        [
                            CellValue.string(value: " ")
                        ]
                    ]
                )

                hparams[model.description] = bestHparams

                currentMetricsRowOffset += sets.storage.sets.count + 4

                Task {
                    await tracker.nextModel()
                }
            }

            telegramBot?.broadcast("Completed testing models")

            var collectedModelValidationResults = [ModelTestingResult]()

            logger.info("Results of models validation: ")

            _ = try! adapter?.appendCells(
                [
                    [
                        CellValue.string(value: "Results of models validation: ")
                    ]
                ],
                format: .bold
            )

            logger.info("model\t\(HyperParamSet.header)\t\(MeagerMetricSeries.headerWithExecutionTime)")

            _ = try! adapter?.appendCells(
                [
                    ([CellValue.string(value: "model")] + HyperParamSet.headerItems + MeagerMetricSeries.headerItemsWithExecutionTime)
                ]
            )

            currentMetricsRowOffset += 2

            let sortedModels = MODELS_FOR_COMPARISON.sorted {
                $0.architecture.index + $0.platform.index < $1.architecture.index + $0.platform.index
            }

            for model in sortedModels {

                let modelHparams = hparams[model.description]!

                do {
                    let (metrics, executionTime) = try await traceExecutionTime(logger) { () -> [OpenKeTester.Metrics] in
                        switch model.platform {
                            case .openke:
                                throw NotImplementedError.platformIsNotSupported(name: "openke")
                                // return try await OpenKeTester(
                                //     model: model.architecture.asOpenKeModel,
                                //     env: env_,
                                //     corpus: corpus_,
                                //     nWorkers: nWorkers_,
                                //     remove: remove_,
                                //     gpu: gpu_,
                                //     differentGpus: differentGpus_,
                                //     terminationDelay: terminationDelay_
                                // ).runSingleTest(
                                //    seeds: seeds_.count > 0 ? seeds_ : nil,
                                //    delay: delay_,
                                //    cvSplitIndex: 0,
                                //    hparams: modelHparams,
                                //    usingValidationSubset: true
                                // )
                            case .grapex:
                                throw NotImplementedError.platformIsNotSupported(name: "grapex")
                                // return try await GrapexTester(
                                //     model: model.architecture.asGrapexModel,
                                //     env: grapexRoot_,
                                //     corpus: corpus_,
                                //     nWorkers: nWorkers_,
                                //     remove: remove_,
                                //     gpu: gpu_,
                                //     differentGpus: differentGpus_,
                                //     terminationDelay: terminationDelay_
                                // ).runSingleTest(
                                //     seeds: seeds_.count > 0 ? seeds_ : nil,
                                //     delay: delay_,
                                //     cvSplitIndex: 0,
                                //     hparams: modelHparams,
                                //     usingValidationSubset: true
                                // )
                        }
                    }

                    // logger.info("Computing mean...")

                    // print(metrics)

                    let meanMetrics = metrics.mean.mean.mean

                    // logger.info("Computed mean")

                    collectedModelValidationResults.append((meanMetrics: meanMetrics, hparams: hparams[model.description]!, executionTime: executionTime))
                    
                    logger.info("\(model)\t\(modelHparams)\t\(meanMetrics.descriptionWithExecutionTime(executionTime))")

                    _ = try! adapter?.appendCells(
                        [
                            ([CellValue.string(value: model.description)] + modelHparams.descriptionItems + meanMetrics.descriptionItemsWithExecutionTime(executionTime))
                        ]
                    )
                } catch let error {
                    logger.error("Unexpected error \(error), cannot complete testing")
                    return 
                }
            }

            if let unwrappedAdapter = adapter {
                _ = unwrappedAdapter.emphasizeCells(
                    collectedModelValidationResults.getOptimalValueLocations(offset: CellLocation(row: currentMetricsRowOffset, column: nTunableHparams + 1)),
                    sheet: unwrappedAdapter.lastSheetId
                )
            }

            if let unwrappedFormatRanges = formatRanges, unwrappedFormatRanges.conditionalFormatRules.first!.ranges.count > 0 {
                unwrappedFormatRanges.addMeasurements(
                    height: MODELS_FOR_COMPARISON.count,
                    offset: CellLocation(
                        row: currentMetricsRowOffset,
                        column: nTunableHparams + 1
                    )
                )

                _ = adapter?.addConditionalFormatRules(unwrappedFormatRanges.conditionalFormatRules)
            }

            if let unwrappedFormatRanges = numberFormatRanges, unwrappedFormatRanges.numberFormatRules.count > 0 {
                unwrappedFormatRanges.addMeasurements(
                    height: MODELS_FOR_COMPARISON.count,
                    offset: CellLocation(
                        row: currentMetricsRowOffset,
                        column: nTunableHparams + 1
                    )
                )

                _ = adapter?.addNumberFormatRules(unwrappedFormatRanges.numberFormatRules)
            }

            let batchUpdateResponse = try! await adapter?.commit(dryRun: dryRun_, logger: logger)

            if let unwrappedResponse = batchUpdateResponse {
                logger.trace(Logger.Message(stringLiteral: "Google sheets api response: "))
                logger.trace(Logger.Message(stringLiteral: String(data: unwrappedResponse, encoding: .utf8)!))
            }

            telegramBot?.broadcast("Completed comparing models")
        } // Blocking task
    } // run
} // CompareModels

