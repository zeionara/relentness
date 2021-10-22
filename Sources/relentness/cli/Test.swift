import Foundation
import ArgumentParser
import Logging
import wickedData

enum Model: String, CaseIterable, ExpressibleByArgument {
    case transe, complex
}

public struct Test: ParsableCommand {
    @Option(name: .shortAndLong, help: "Identifier which allows to obtain reproducible results")
    var seed = 17

    @Argument(help: "Path to folder which keeps the dataset for testing")
    var path: String

    @Option(name: .shortAndLong, help: "Model name")
    var model: Model = .transe

    @Option(name: .shortAndLong, help: "Conda environment name to activate before running test")
    var env: String = "reltf"

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
        let path_ = path
        let seed_ = seed
        let model_ = model

        BlockingTask {
            var output: String = ""

            do { 
                output = try await runSubprocessAndGetOutput(
                    path: "/home/zeio/anaconda3/envs/\(env_)/bin/python",
                    args: ["-m", "relentness", "test", "./Assets/Corpora/\(path_)/", "-s", "\(seed_)", "-m", model_.rawValue, "-t"],
                    env: ["TF_CPP_MIN_LOG_LEVEL": "3"]
                )
            } catch {
                print("Unexpected error \(error), cannot complete testing")
            }

            print(output)
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
