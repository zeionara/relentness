import Foundation
import ArgumentParser
import Logging
import wickedData
import ahsheet

let MODELS_FOR_COMPARISON: [ModelImpl] = [
    ModelImpl(architecture: .se, platform: .grapex),
    ModelImpl(architecture: .transe, platform: .grapex),
    ModelImpl(architecture: .transe, platform: .openke),
    ModelImpl(architecture: .complex, platform: .openke)
]

public typealias ModelTestingResult = (meanMetrics: MeagerMetricSeries, hparams: HyperParamSet, executionTime: Double) // TODO: Change MeagerMetricSeries to an abstract MetricSeries data type

public extension Collection where Element == ModelTestingResult {
    func getOptimalValueLocations(offset: CellLocation = CellLocation(row: 0, column: 0)) -> [CellLocation] {
        var optimalValues = (
            meanRank: Double.infinity, meanReciprocalRank: -Double.infinity, hitsAtOne: -Double.infinity, hitsAtThree: -Double.infinity, hitsAtTen: -Double.infinity,
            time: Double.infinity, totalTime: Double.infinity, executionTime: Double.infinity
        )
        var optimalValueIndices = (
            meanRank: [Int](), meanReciprocalRank: [Int](), hitsAtOne: [Int](), hitsAtThree: [Int](), hitsAtTen: [Int](),
            time: [Int](), totalTime: [Int](), executionTime: [Int]() 
        )

        for (i, testingResult) in self.enumerated() {
            if testingResult.meanMetrics.meanRank < optimalValues.meanRank {
                optimalValues.meanRank = testingResult.meanMetrics.meanRank
                optimalValueIndices.meanRank = [i]
            } else if testingResult.meanMetrics.meanRank == optimalValues.meanRank {
                optimalValueIndices.meanRank.append(i)
            }

            if testingResult.meanMetrics.meanReciprocalRank > optimalValues.meanReciprocalRank {
                optimalValues.meanReciprocalRank = testingResult.meanMetrics.meanReciprocalRank
                optimalValueIndices.meanReciprocalRank = [i]
            } else if testingResult.meanMetrics.meanReciprocalRank == optimalValues.meanReciprocalRank {
                optimalValueIndices.meanReciprocalRank.append(i)
            }

            if testingResult.meanMetrics.hitsAtOne > optimalValues.hitsAtOne {
                optimalValues.hitsAtOne = testingResult.meanMetrics.hitsAtOne
                optimalValueIndices.hitsAtOne = [i]
            } else if testingResult.meanMetrics.hitsAtOne == optimalValues.hitsAtOne {
                optimalValueIndices.hitsAtOne.append(i)
            }

            if testingResult.meanMetrics.hitsAtThree > optimalValues.hitsAtThree {
                optimalValues.hitsAtThree = testingResult.meanMetrics.hitsAtThree
                optimalValueIndices.hitsAtThree = [i]
            } else if testingResult.meanMetrics.hitsAtThree == optimalValues.hitsAtThree {
                optimalValueIndices.hitsAtThree.append(i)
            }

            if testingResult.meanMetrics.hitsAtTen > optimalValues.hitsAtTen {
                optimalValues.hitsAtTen = testingResult.meanMetrics.hitsAtTen
                optimalValueIndices.hitsAtTen = [i]
            } else if testingResult.meanMetrics.hitsAtTen == optimalValues.hitsAtTen {
                optimalValueIndices.hitsAtTen.append(i)
            }

            if let unwrappedTime = testingResult.meanMetrics.time {
                if unwrappedTime < optimalValues.time {
                    optimalValues.time = unwrappedTime
                    optimalValueIndices.time = [i]
                } else if unwrappedTime == optimalValues.time {
                    optimalValueIndices.time.append(i)
                }
            }

            print("Checking total time...")
            if let unwrappedTime = testingResult.meanMetrics.totalTime ?? testingResult.meanMetrics.time {
                print("Total time is not none")
                if unwrappedTime < optimalValues.totalTime {
                    optimalValues.totalTime = unwrappedTime
                    optimalValueIndices.totalTime = [i]
                } else if unwrappedTime == optimalValues.totalTime {
                    optimalValueIndices.totalTime.append(i)
                }
            }

            if testingResult.executionTime < optimalValues.executionTime {
                optimalValues.executionTime = testingResult.executionTime
                optimalValueIndices.executionTime = [i]
            } else if testingResult.executionTime == optimalValues.executionTime {
                optimalValueIndices.executionTime.append(i)
            }
        }

        let meanRankCellLocations = optimalValueIndices.meanRank.count < count ? optimalValueIndices.meanRank.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.meanRank.rawValue)
        } : [CellLocation]()
        
        let meanReciprocalRankCellLocations = optimalValueIndices.meanReciprocalRank.count < count ? optimalValueIndices.meanReciprocalRank.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.meanReciprocalRank.rawValue)
        } : [CellLocation]()
        
        let hitsAtOneCellLocations = optimalValueIndices.hitsAtOne.count < count ? optimalValueIndices.hitsAtOne.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.hitsAtOne.rawValue)
        } : [CellLocation]()
        
        let hitsAtThreeCellLocations = optimalValueIndices.hitsAtThree.count < count ? optimalValueIndices.hitsAtThree.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.hitsAtThree.rawValue)
        } : [CellLocation]()
        
        let hitsAtTenCellLocations = optimalValueIndices.hitsAtTen.count < count ? optimalValueIndices.hitsAtTen.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.hitsAtTen.rawValue)
        } : [CellLocation]()

        let timeCellLocations = optimalValueIndices.time.count < count ? optimalValueIndices.time.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.time.rawValue)
        } : [CellLocation]()

        let totalTimeCellLocations = optimalValueIndices.totalTime.count < count ? optimalValueIndices.totalTime.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.totalTime.rawValue)
        } : [CellLocation]()

        let executionTimeCellLocations = optimalValueIndices.executionTime.count < count ? optimalValueIndices.executionTime.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.executionTime.rawValue)
        } : [CellLocation]()

        return meanRankCellLocations + meanReciprocalRankCellLocations + hitsAtOneCellLocations + hitsAtThreeCellLocations + hitsAtTenCellLocations + timeCellLocations + totalTimeCellLocations +
            executionTimeCellLocations
    }
}

public enum ComparisonException: Error {
    case invalidModel(model: ModelImpl, message: String? = nil)
}

extension Data: CustomStringConvertible {
    var description: String {
        String(decoding: self, as: UTF8.self)
    }
}

public struct CompareModels: ParsableCommand {
    @Argument(help: "Name of folder which keeps the dataset for testing")
    var corpus: String

    // @Option(name: .shortAndLong, help: "Model name")
    // var model: Model = .transe

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"

    @Option(help: "Path to the cloned repository with the grapex framework with respect to the home directory for current user")
    var grapexRoot: String = "grapex"

    @Option(name: .shortAndLong, help: "Maximum number of concurrently running tests")
    var nWorkers: Int? // If this argument takes a negative value, then it is considered that no value was provided by user (comment is not relevant)

    @Option(name: .shortAndLong, help: "Path to yaml file with hyperparams")
    var path: String // If this argument takes a negative value, then it is considered that no value was provided by user (comment is not relevant)

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

    public static var configuration = CommandConfiguration(
        commandName: "compare-models",
        abstract: "Compare knowledge graph embedding models by selecting optimal set of hyperparams and performing validation"
    )

    public init() {}

    mutating public func run() {
        print(CommandLine.arguments.joined(separator: " "))

        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  

        let logger = Logger(level: verbose ? .trace : .info, label: "main")
        let exportToGoogleSheets_ = exportToGoogleSheets

        let env_ = env
        let grapexRoot_ = grapexRoot
        let corpus_ = corpus
        // let model_ = model
        let nWorkers_ = nWorkers
        let seeds_ = seeds

        let remove_ = remove
        let gpu_ = gpu
        let differentGpus_ = differentGpus

        let path_ = path
        let delay_ = delay
        let terminationDelay_ = terminationDelay

        BlockingTask {
            // let wrapper = try! GoogleApiSessionWrapper()
            let adapter = exportToGoogleSheets_ ? try? GoogleSheetsApiAdapter() : nil

            // try! adapter.append([["foo", "bar"], ["baz"]])

            var currentMetricsRowOffset = 0
            let formatRanges = adapter == nil ? nil : MeagerMetricSetFormatRanges(sheet: adapter!.lastSheetId + 1)  
            let numberFormatRanges = adapter == nil ? nil : MeagerMetricSetNumberFormatRanges(sheet: adapter!.lastSheetId + 1)

            _ = try! adapter?
                     .addSheet(tabColor: "e67c73") // "novel-sheet", 
                     // .appendCells(
                     //     [
                     //         [
                     //             CellValue.string(value: "foo"), CellValue.number(value: 2.3)
                     //         ],
                     //         [
                     //             CellValue.number(value: 1.7), CellValue.bool(value: false)
                     //         ]
                     //     ]
                     // )
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


            // async let batchUpdateResponse = adapter?.commit(dryRun: false)

            // print("foo")

            // if let unwrappedResponse = try? await batchUpdateResponse {
            //     print(String(data:  unwrappedResponse, encoding: .utf8)!)
            // }
        // }


        // print("Sheets:")
        // for sheet in try! wrapper.getSpreadsheetMeta().sheets {
        //     print(sheet)
        // }

        // try! wrapper.setSheetData(                                                                                                                                                                                                                                                       
        //     SheetData(                                                                                                                                                                                             
        //         range: "sheets-adapter-testing!A1",                                                                                                                                                                                  
        //         values: [                                                                                                                                                                                          
        //             [                                                                                                                                                                                              
        //                 "foo", "bar"                                                                                                                                                                               
        //             ]                                                                                                                                                                                              
        //         ]                                                                                                                                                                                                  
        //     )                                                                                                                                                                                                      
        // )            

        // let adapter = try! GoogleSheetsApiAdapter()

        // try! adapter.append([["foo", "bar"], ["baz"]])
        // try! adapter.append([["qux"]])

        // print(try! adapter.add_sheet(title: "list-added-from-cli"))


        // print(String(data: try! JSONEncoder().encode(["requests": [addSheetRequest, appendDataRequest]]), encoding: .utf8)!)


        // switch addSheetRequest {
        //     case let .addSheet(request):
        //         request
        //     default:
        //         "No element"
        // }


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

            // BlockingTask {
                let sets = try! HyperParamSets(corpus_, model.architecture.rawValue, path_)
                var collectedModelTestingResults = [ModelTestingResult]()

                formatRanges?.addMeasurements(
                    height: sets.storage.sets.count,
                    offset: CellLocation(
                        row: currentMetricsRowOffset,
                        column: nTunableHparams
                    )
                )

                numberFormatRanges?.addMeasurements(
                    height: sets.storage.sets.count,
                    offset: CellLocation(
                        row: currentMetricsRowOffset,
                        column: nTunableHparams
                    )
                )

                for hparams in sets.storage.sets {
                    do {
                        let (metrics, executionTime) = try await traceExecutionTime(logger) { () -> [[OpenKeTester.Metrics]] in
                            switch model.platform {
                                case .openke:
                                    return try await OpenKeTester( // TODO: Create the instance once and then reuse it
                                        model: model.architecture.asOpenKeModel,
                                        env: env_,
                                        corpus: corpus_,
                                        nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                                        remove: remove_,
                                        gpu: gpu_,
                                        differentGpus: differentGpus_,
                                        terminationDelay: terminationDelay_
                                    ).run(
                                        seeds: seeds_.count > 0 ? seeds_ : nil,
                                        delay: delay_,
                                        hparams: hparams
                                    )
                                case .grapex:
                                    return try await GrapexTester( // TODO: Create the instance once and then reuse it
                                        model: model.architecture.asGrapexModel,
                                        env: grapexRoot_,
                                        corpus: corpus_,
                                        nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                                        remove: remove_,
                                        gpu: gpu_,
                                        differentGpus: differentGpus_,
                                        terminationDelay: terminationDelay_
                                    ).run(
                                        seeds: seeds_.count > 0 ? seeds_ : nil,
                                        delay: delay_,
                                        hparams: hparams
                                    )
                                // default:
                                //    throw ComparisonException.invalidModel(model: model, message: "Platform \(model.platform) is not supported")
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
                    } catch {
                        print("Unexpected error \(error), cannot complete testing")
                    }
                }

                let bestHparams = collectedModelTestingResults.sorted{ (lhs, rhs) in
                    lhs.meanMetrics.weightedSum(executionTime: lhs.executionTime) > rhs.meanMetrics.weightedSum(executionTime: rhs.executionTime)
                }.first!.hparams

                print("Optimal values:")
                print(collectedModelTestingResults.getOptimalValueLocations(offset: CellLocation(row: currentMetricsRowOffset, column: nTunableHparams))) 

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
            // }
        }

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
        // var collectedModelValidationResults = [Model: ModelTestingResult]()
        for model in sortedModels {
            // logger.info("Validating model \(model)...")
            let modelHparams = hparams[model.description]!
            // BlockingTask {
                do {
                    let (metrics, executionTime) = try await traceExecutionTime(logger) { () -> [OpenKeTester.Metrics] in
                        switch model.platform {
                            case .openke:
                                return try await OpenKeTester(
                                    model: model.architecture.asOpenKeModel,
                                    env: env_,
                                    corpus: corpus_,
                                    nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                                    remove: remove_,
                                    gpu: gpu_,
                                    differentGpus: differentGpus_,
                                    terminationDelay: terminationDelay_
                                ).runSingleTest(
                                   seeds: seeds_.count > 0 ? seeds_ : nil,
                                   delay: delay_,
                                   cvSplitIndex: 0,
                                   hparams: modelHparams,
                                   usingValidationSubset: true
                                )
                            case .grapex:
                                return try await GrapexTester( // TODO: Create the instance once and then reuse it
                                    model: model.architecture.asGrapexModel,
                                    env: grapexRoot_,
                                    corpus: corpus_,
                                    nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                                    remove: remove_,
                                    gpu: gpu_,
                                    differentGpus: differentGpus_,
                                    terminationDelay: terminationDelay_
                                ).runSingleTest(
                                    seeds: seeds_.count > 0 ? seeds_ : nil,
                                    delay: delay_,
                                    cvSplitIndex: 0,
                                    hparams: modelHparams,
                                    usingValidationSubset: true
                                )
                            // default:
                            //     throw ComparisonException.invalidModel(model: model, message: "Platform \(model.platform) is not supported")
                        }
                    }

                    let meanMetrics = metrics.mean.mean.mean

                    collectedModelValidationResults.append((meanMetrics: meanMetrics, hparams: hparams[model.description]!, executionTime: executionTime))
                    
                    logger.info("\(model)\t\(modelHparams)\t\(meanMetrics.descriptionWithExecutionTime(executionTime))")

                    _ = try! adapter?.appendCells(
                        [
                            ([CellValue.string(value: model.description)] + modelHparams.descriptionItems + meanMetrics.descriptionItemsWithExecutionTime(executionTime))
                        ]
                    )

                    // collectedModelTestingResults[model] = (meanMetrics: meanMetrics, hparams: modelHparams, executionTime: executionTime)
                } catch {
                    print("Unexpected error \(error), cannot complete testing")
                }
            }

            if let unwrappedAdapter = adapter {
                print("Validation results")
                print(collectedModelValidationResults)
                _ = unwrappedAdapter.emphasizeCells(
                    collectedModelValidationResults.getOptimalValueLocations(offset: CellLocation(row: currentMetricsRowOffset, column: nTunableHparams + 1)),
                    sheet: unwrappedAdapter.lastSheetId
                )
            }

            if let unwrappedFormatRanges = formatRanges, unwrappedFormatRanges.conditionalFormattingRules.first!.ranges.count > 0 {
                unwrappedFormatRanges.addMeasurements(
                    height: MODELS_FOR_COMPARISON.count,
                    offset: CellLocation(
                        row: currentMetricsRowOffset,
                        column: nTunableHparams + 1
                    )
                )

                _ = adapter?.addConditionalFormattingRules(unwrappedFormatRanges.conditionalFormattingRules)
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

            let batchUpdateResponse = try! await adapter?.commit(dryRun: false)

            if let unwrappedResponse = batchUpdateResponse {
                logger.info(Logger.Message(stringLiteral: String(data: unwrappedResponse, encoding: .utf8)!))
            }
        }
    }
}

