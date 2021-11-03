import Foundation
import ArgumentParser
import Logging
import wickedData

let MODELS_FOR_COMPARISON: [Model] = [.transe, .complex]

public typealias ModelTestingResult = (meanMetrics: MeagerMetricSeries, hparams: HyperParamSet, executionTime: Double) // TODO: Change MeagerMetricSeries to an abstract MetricSeries data type

public struct CompareModels: ParsableCommand {
    @Argument(help: "Name of folder which keeps the dataset for testing")
    var corpus: String

    // @Option(name: .shortAndLong, help: "Model name")
    // var model: Model = .transe

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"

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

    @Flag(name: .long, help: "Enably wordy way of logging")
    var discardExistingLogFile = false

    @Option(name: .shortAndLong, help: "Name of log file")
    var logFileName: String?

    @Option(name: .long, help: "Delay to wait for before running consecutive tests (in seconds)")
    var delay: Double?

    public static var configuration = CommandConfiguration(
        commandName: "compare-models",
        abstract: "Compare knowledge graph embedding models by selecting optimal set of hyperparams and performing validation"
    )

    public init() {}

    mutating public func run() {

        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  

        let logger = Logger(level: verbose ? .trace : .info, label: "main")

        let env_ = env
        let corpus_ = corpus
        // let model_ = model
        let nWorkers_ = nWorkers
        let seeds_ = seeds

        let remove_ = remove
        let gpu_ = gpu
        let differentGpus_ = differentGpus

        let path_ = path
        let delay_ = delay


        for model in MODELS_FOR_COMPARISON {
            logger.info("Testing model \(model)...")
            logger.info("\(HyperParamSet.header)\t\(MeagerMetricSeries.headerWithExecutionTime)")

            BlockingTask {
                let sets = HyperParamSets(corpus_, model.rawValue, path_)
                var collectedModelTestingResults = [ModelTestingResult]()

                for hparams in sets.storage.sets {
                    do {
                        let (metrics, executionTime) = try await traceExecutionTime(logger) { () -> [[OpenKeTester.Metrics]] in
                            try await OpenKeTester(
                                model: model.asOpenKeModel,
                                env: env_,
                                corpus: corpus_,
                                nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                                remove: remove_,
                                gpu: gpu_,
                                differentGpus: differentGpus_
                            ).run(
                                seeds: seeds_.count > 0 ? seeds_ : nil,
                                delay: delay_,
                                hparams: hparams
                            )
                        }

                        let meanMetrics = mean(sets: metrics).mean.mean.mean
                        collectedModelTestingResults.append((meanMetrics: meanMetrics, hparams: hparams, executionTime: executionTime))

                        logger.info("\(hparams)\t\(meanMetrics.descriptionWithExecutionTime(executionTime))") // Firstly average by cv-splits, then by seeds, then by filters and finally by corruption strategy
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
            }
        }
    }
}

