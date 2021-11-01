import Foundation
import ArgumentParser
import Logging
import wickedData

public struct HyperSearch: ParsableCommand {
    @Argument(help: "Name of folder which keeps the dataset for testing")
    var corpus: String

    @Option(name: .shortAndLong, help: "Model name")
    var model: Model = .transe

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

    public static var configuration = CommandConfiguration(
        commandName: "hsearch",
        abstract: "Run model testing on different sets of hyperparameters"
    )

    public init() {}

    mutating public func run() {

        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  

        let logger = Logger(level: verbose ? .trace : .info, label: "main")

        let env_ = env
        let corpus_ = corpus
        let model_ = model
        let nWorkers_ = nWorkers
        let seeds_ = seeds

        let remove_ = remove
        let gpu_ = gpu
        let differentGpus_ = differentGpus

        let path_ = path


        logger.info("\(HyperParamSet.header)\t\(MeagerMetricSeries.headerWithExecutionTime)")

        BlockingTask {
            let sets = HyperParamSets(corpus_, model_.rawValue, path_)

            for hparams in sets.storage.sets {
                do {
                    let (metrics, executionTime) = try await traceExecutionTime(logger) { () -> [[OpenKeTester.Metrics]] in
                        // print("Calling tester...")
                        try await OpenKeTester(
                            model: model_.asOpenKeModel,
                            env: env_,
                            corpus: corpus_,
                            nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                            remove: remove_,
                            gpu: gpu_,
                            differentGpus: differentGpus_
                        ).run(
                            seeds: seeds_.count > 0 ? seeds_ : nil,
                            hparams: hparams
                        )
                        // print("Called tester")
                        // return result
                    }

                    logger.info("\(hparams)\t\(mean(sets: metrics).mean.mean.mean.descriptionWithExecutionTime(executionTime))") // Firstly average by cv-splits, then by seeds, then by filters and finally by corruption strategy
                    // print("\(hparams)\t\(mean(sets: metrics).mean.mean.mean.descriptionWithExecutionTime(executionTime))") // Firstly average by cv-splits, then by seeds, then by filters and finally by corruption strategy
                    // print("Averaged \(metrics.count) x \(metrics.first!.count) x \(metrics.first!.first!.subsets.count) batches")
                    // for metricsForCvSplit in metrics {
                    //     for metricsForSeed in metricsForCvSplit {
                    //         print(metricsForSeed.mean.mean)
                    //     }
                    // }
                    // print(metrics.map{$0.mean.mean})
                    // print(metrics.mean.mean.mean) // The first is for different seeds, the second for different filters, the third is for different corruption strategies
                } catch {
                    print("Unexpected error \(error), cannot complete testing")
                }
            }
        }
    }
}
