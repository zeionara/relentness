import Foundation
import ArgumentParser
import Logging
import wickedData
import ahsheet

let MODELS_FOR_COMPARISON: [ModelImpl] = [
    // ModelImpl(architecture: .se, platform: .grapex),
    // ModelImpl(architecture: .transe, platform: .grapex),
    ModelImpl(architecture: .transe, platform: .openke),
    // ModelImpl(architecture: .complex, platform: .openke)
]

public typealias ModelTestingResult = (meanMetrics: MeagerMetricSeries, hparams: HyperParamSet, executionTime: Double) // TODO: Change MeagerMetricSeries to an abstract MetricSeries data type

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
                                 CellValue.string(value: "Command:"), CellValue.string(value: CommandLine.arguments.joined(separator: " "))
                             ]
                         ],
                         format: .bold
                     )

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

            // BlockingTask {
                let sets = try! HyperParamSets(corpus_, model.architecture.rawValue, path_)
                var collectedModelTestingResults = [ModelTestingResult]()

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
            // }
        }

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

            let _ = try? await adapter?.commit(dryRun: false)

        }
    }
}

