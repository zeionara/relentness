import Foundation
import ArgumentParser
import Logging
import wickedData

// typealias ModelImpl = (architecture: Model, platform: Platform)

public struct ModelImpl: CustomStringConvertible {
    public let architecture: Model
    public let platform: Platform

    public var description: String {
        "\(architecture)@\(platform)"
    }
}

public enum Platform: String, CaseIterable, ExpressibleByArgument {
    case openke, grapex

    public var index: Int {
       switch self {
           case .grapex:  
              return -1
           case .openke:
              return 0
       }
    }
}

public enum ModelConversionError: Error {
   case modelIsNotImplemented(platform: Platform)
}

public enum Model: String, CaseIterable, ExpressibleByArgument {
    case transe, complex, se

    public var asOpenKeModel: OpenKeModel {
        get throws {
            switch self {
            case .transe:
                return .transe
            case .complex:
                return .complex
            case .se:
                throw ModelConversionError.modelIsNotImplemented(platform: .openke) 
            }
        }
    }

    public var asGrapexModel: GrapexTester.ModelType {
        get throws {
            switch self {
                case .transe:
                    return .transe
                case .se:
                    return .se
                case .complex:
                    throw ModelConversionError.modelIsNotImplemented(platform: .grapex)
            }
        }
    }

    public var index: Int {
       switch self {
           case .se:
               return -1 
           case .transe:
              return 0
           case .complex:  
              return 1
       }
    }
}

public struct Test: ParsableCommand {
    @Option(name: .shortAndLong, help: "Identifier which allows to obtain reproducible results")
    var seed: Int?

    @Argument(help: "Name of folder which keeps the dataset for testing")
    var corpus: String

    @Option(name: .shortAndLong, help: "Model name")
    var model: Model = .transe

    @Option(name: .shortAndLong, help: "Index of cvsplit to perform testing on")
    var cvSplitIndex: Int = 0

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"
    
    @Flag(name: .shortAndLong, help: "Delete trained model files")
    var remove = false

    @Flag(name: .shortAndLong, help: "Enable gpu")
    var gpu = false

    @Flag(name: .shortAndLong, help: "Run each worker on different gpu")
    var differentGpus = false

    public static var configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Knowledge graph models testing manager"
    )

    public init() {}

    mutating public func run() {
        // assert (model == "transe" || model == "complex")
        var logger = Logger(label: "main")
        logger.logLevel = .info

        let env_ = env
        let corpus_ = corpus
        let seed_ = seed
        let model_ = model
        let cvSplitIndex_ = cvSplitIndex

        let remove_ = remove
        let gpu_ = gpu
        let differentGpus_ = differentGpus

        BlockingTask {
            // var output: String = ""

            do { 
                let (metrics, executionTime) = try await traceExecutionTime(logger) {
                    try await OpenKeTester(
                        model: model_.asOpenKeModel,
                        env: env_,
                        corpus: corpus_,
                        remove: remove_,
                        gpu: gpu_,
                        differentGpus: differentGpus_
                    ).runSingleTest(
                        seed: seed_,
                        cvSplitIndex: cvSplitIndex_
                    )
                }

                print(MeagerMetricSeries.headerWithExecutionTime)
                print(metrics.mean.mean.descriptionWithExecutionTime(executionTime))
                // output = try await runSubprocessAndGetOutput(
                //     path: "/home/zeio/anaconda3/envs/\(env_)/bin/python",
                //     args: ["-m", "relentness", "test", "./Assets/Corpora/\(path_)/", "-s", "\(seed_)", "-m", model_.rawValue, "-t"],
                //     env: ["TF_CPP_MIN_LOG_LEVEL": "3"]
                // )
            } catch {
                print("Unexpected error \(error), cannot complete testing")
            }
            
            // let metrics = MeagerMetricSet(output)
            // print(metrics.mean.mean)
        }
        

        // let task = Process()

        // task.executableURL = URL(fileURLWithPath: "/home/zeio/anaconda3/envs/\(env)/bin/python")
        // task.environment = ["TF_CPP_MIN_LOG_LEVEL": "3"]
        // task.arguments = ["-m", "relentness", "test", "./Assets/Corpora/\(path)/", "-s", "\(seed)", "-m", model.rawValue, "-t"]

        // let outputPipe = Pipe()
        // let inputPipe = Pipe()

        // task.standardOutput = outputPipe
        // task.standardInput = inputPipe

        // try! task.run()

        // let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

        // let output = String(decoding: outputData, as: UTF8.self)

        // print(output.dropLast())

        // for i in 0..<nFolds {
        //     createDirectory("\(path)/\(String(format: "%04i", i))")
        // }

        // let query = """
        // SELECT DISTINCT ?foo ?fooLabel ?bar ?barLabel WHERE 
        // {
        //   ?foo wdt:P2152 ?bar.
        //   filter (?foo != ?bar).
        //   SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        // }
        // LIMIT 7
        // """
        // let seed_ = seed
        // let path_ = path
        // BlockingTask {
        //     var i = 0
        //     try! await WikiDataAdapter().sample(DemoQuery(text: query)).cv(seed: seed_) { subset in
        //         let currentDirPath = "\(path_)/\(String(format: "%04i", i))"
        //         i += 1
        //         logger.info("\(subset)")
        //         // logger.info("\(subset.id2relationship.asOpenKEReversedIdMapping)")
        //         writeLines("\(currentDirPath)/relation2id.txt", subset.id2relationship.asOpenKEReversedIdMapping, logger: logger)
        //         writeLines("\(currentDirPath)/entity2id.txt", subset.id2entity.asOpenKEReversedIdMapping, logger: logger)
        //         // logger.info("\(subset.train.asOpenKETriples)")
        //         writeLines("\(currentDirPath)/train2id.txt", subset.train.asOpenKETriples, logger: logger)
        //         writeLines("\(currentDirPath)/test2id.txt", subset.test.asOpenKETriples, logger: logger)
        //         writeLines("\(currentDirPath)/valid2id.txt", subset.validation.asOpenKETriples, logger: logger)
        //     }
        // }
        // // print(String(format: "%04i", 12))

        // logger.info("Writing results to '\(path)'")
    }
}

public struct TestWithSeeds: ParsableCommand {
    @Argument(help: "Name of folder which keeps the dataset for testing")
    var corpus: String

    @Option(name: .shortAndLong, help: "Model name")
    var model: Model = .transe

    @Option(name: .shortAndLong, help: "Index of cvsplit to perform testing on")
    var cvSplitIndex: Int = 0

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"

    @Option(name: .shortAndLong, help: "Maximum number of concurrently running tests")
    var nWorkers: Int? // If this argument takes a negative value, then it is considered that no value was provided by user (comment is not relevant)

    @Argument(help: "Seeds to use during testing")
    var seeds: [Int] = [Int]()

    @Flag(name: .shortAndLong, help: "Delete trained model files")
    var remove = false

    @Flag(name: .shortAndLong, help: "Enable gpu")
    var gpu = false

    @Flag(name: .shortAndLong, help: "Run each worker on different gpu")
    var differentGpus = false

    public static var configuration = CommandConfiguration(
        commandName: "test-with-seeds",
        abstract: "Test a model using multiple seeds, then average results"
    )

    public init() {}

    mutating public func run() {
        var logger = Logger(label: "main")
        logger.logLevel = .info

        let env_ = env
        let corpus_ = corpus
        let model_ = model
        let cvSplitIndex_ = cvSplitIndex
        let nWorkers_ = nWorkers
        let seeds_ = seeds

        let remove_ = remove
        let gpu_ = gpu
        let differentGpus_ = differentGpus

        BlockingTask {
            do { 
                let (metrics, executionTime) = try await traceExecutionTime(logger) {
                    try await OpenKeTester(
                        model: model_.asOpenKeModel,
                        env: env_,
                        corpus: corpus_,
                        nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                        remove: remove_,
                        gpu: gpu_,
                        differentGpus: differentGpus_
                    ).runSingleTest(
                        seeds: seeds_.count > 0 ? seeds_ : nil,
                        cvSplitIndex: cvSplitIndex_
                    )
                }

                // print(metrics.map{$0.mean.mean})
                print(MeagerMetricSeries.headerWithExecutionTime)
                print(metrics.mean.mean.mean.descriptionWithExecutionTime(executionTime)) // The first is for different seeds, the second for different filters, the third is for different corruption strategies
            } catch {
                print("Unexpected error \(error), cannot complete testing")
            }
        }
    }
}

public struct TestAllFolds: ParsableCommand {
    @Argument(help: "Name of folder which keeps the dataset for testing")
    var corpus: String

    @Option(name: .shortAndLong, help: "Model name")
    var model: Model = .transe

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"

    @Option(name: .shortAndLong, help: "Maximum number of concurrently running tests")
    var nWorkers: Int? // If this argument takes a negative value, then it is considered that no value was provided by user (comment is not relevant)

    @Argument(help: "Seeds to use during testing")
    var seeds: [Int] = [Int]() // [17, 2000]

    @Flag(name: .shortAndLong, help: "Delete trained model files")
    var remove = false

    @Flag(name: .shortAndLong, help: "Enable gpu")
    var gpu = false

    @Flag(name: .shortAndLong, help: "Run each worker on different gpu")
    var differentGpus = false

    public static var configuration = CommandConfiguration(
        commandName: "test-all-folds",
        abstract: "Test a model on all cv folds, then average results"
    )

    public init() {}

    mutating public func run() {
        var logger = Logger(label: "main")
        logger.logLevel = .info

        let env_ = env
        let corpus_ = corpus
        let model_ = model
        let nWorkers_ = nWorkers
        let seeds_ = seeds

        let remove_ = remove
        let gpu_ = gpu
        let differentGpus_ = differentGpus

        BlockingTask {
            do {
                let (metrics, executionTime) = try await traceExecutionTime(logger) {
                    try await OpenKeTester(
                        model: model_.asOpenKeModel,
                        env: env_,
                        corpus: corpus_,
                        nWorkers: nWorkers_, // > 0 ? nWorkers_ : nil
                        remove: remove_,
                        gpu: gpu_,
                        differentGpus: differentGpus_
                    ).run(
                        seeds: seeds_.count > 0 ? seeds_ : nil
                    )
                }

                print(MeagerMetricSeries.headerWithExecutionTime)
                print(mean(sets: metrics).mean.mean.mean.descriptionWithExecutionTime(executionTime)) // Firstly average by cv-splits, then by seeds, then by filters and finally by corruption strategy
                print("Averaged \(metrics.count) x \(metrics.first!.count) x \(metrics.first!.first!.subsets.count) batches")
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
