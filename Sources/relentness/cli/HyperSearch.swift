import Foundation
import ArgumentParser
import Logging
import wickedData
import Swat

public class HyperSearch: ParsableCommand {
    // @Argument(help: "Name of folder which keeps the dataset for testing")
    // var corpus: String

    @Option(name: .shortAndLong, help: "Model name")
    var model: Model = .transe

    @Option(name: .shortAndLong, help: "Model name")
    var platform: Platform = .grapex

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"

    // @Option(name: .shortAndLong, help: "Maximum number of concurrently running tests")
    // var nWorkers: Int? // If this argument takes a negative value, then it is considered that no value was provided by user (comment is not relevant)

    // @Option(name: .shortAndLong, help: "Path to yaml file with hyperparams")
    // var path: String // If this argument takes a negative value, then it is considered that no value was provided by user (comment is not relevant)

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

    @Flag(name: .long, help: "Enable wordy way of logging")
    var discardExistingLogFile = false

    @Option(name: .shortAndLong, help: "Name of log file")
    var logFileName: String?

    @Option(name: .long, help: "Delay to wait for before running consecutive tests (in seconds)")
    var delay: Double?

    public static let configuration = CommandConfiguration(
        commandName: "hsearch",
        abstract: "Run model testing on different sets of hyperparameters"
    )

    public required init() {}

    public func run() throws {

        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  

        let logger = Logger(level: verbose ? .trace : .info, label: "main")

        let configs: [Config] = try ConfigFactory(at: Path.config).make()

        // let env_ = env
        // // let corpus_ = corpus
        // let model_ = model
        // // let nWorkers_ = nWorkers
        // let seeds_ = seeds

        // let remove_ = remove
        // let gpu_ = gpu
        // let differentGpus_ = differentGpus

        // // let path_ = path
        // let delay_ = delay
        // let platform_ = platform

        // configs.forEach{ print($0.name) }

        // logger.info("\(HyperParamSet.header)\t\(MeagerMetricSeries.headerWithExecutionTime)")
        logger.info("\(configs.first!.header)")

        BlockingTask {
            // let sets = try! HyperParamSets(corpus_, model_.rawValue, path_)

            // for hparams in sets.storage.sets {
            for config in configs {
                do {
                    logger.info("\(config.row)")
                    try config.write(to: Path.assets.appendingPathComponent("config_\(config.name).yml"), as: .yaml, userInfo: [PLATFORM_CODING_USER_INFO_KEY: self.platform])
                    // print(try Yams.dump(object: 5.0))
                    // try config.write(to: Path.assets.appendingPathComponent("config_\(config.name).yml"), as: .yaml)
                    // let (metrics, executionTime) = try await traceExecutionTime(logger) { () -> [[OpenKeTester.Metrics]] in
                    //     try await OpenKeTester(
                    //         model: model_.asOpenKeModel,
                    //         env: env_,
                    //         corpus: corpus_,
                    //         nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                    //         remove: remove_,
                    //         gpu: gpu_,
                    //         differentGpus: differentGpus_
                    //     ).run(
                    //         seeds: seeds_.count > 0 ? seeds_ : nil,
                    //         delay: delay_,
                    //         hparams: hparams
                    //     )
                    // }

                    // logger.info("\(hparams)\t\(mean(sets: metrics).mean.mean.mean.descriptionWithExecutionTime(executionTime))") // Firstly average by cv-splits, then by seeds, then by filters and finally by corruption strategy
                } catch {
                    print("Unexpected error \(error), cannot complete testing")
                }
            }
        }
    }
}
