import Foundation
import ArgumentParser
import Logging
import wickedData

public struct GenerateSample: ParsableCommand {
    @Option(name: .shortAndLong, help: "Fraction of target triples which are going to the train subset")
    var trainSize = 0.5

    @Option(name: .shortAndLong, help: "Fraction of target triples which are going to the evaluation subset")
    var evaluationSize = 0.2

    @Option(name: .shortAndLong, help: "Number of parts into which the data will be split")
    var nFolds = 2

    @Option(name: .shortAndLong, help: "Identifier which allows to obtain reproducible results")
    var seed = 17

    @Argument(help: "Path to folder which keeps the generated cv subsets")
    var path: String

    public static var configuration = CommandConfiguration(
        commandName: "sample",
        abstract: "Cross-validation subsets sampler"
    )

    public init() {}

    mutating public func run() {
        var logger = Logger(label: "main")
        logger.logLevel = .info

        // createDirectory(path)

        for i in 0..<nFolds {
            createDirectory("\(path)/\(String(format: "%04i", i))")
        }

        let query = """
        SELECT DISTINCT ?foo ?fooLabel ?bar ?barLabel WHERE 
        {
          ?foo wdt:P2152 ?bar.
          filter (?foo != ?bar).
          SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        }
        LIMIT 7
        """
        let seed_ = seed
        let path_ = path
        BlockingTask {
            var i = 0
            try! await WikiDataAdapter().sample(DemoQuery(text: query)).cv(seed: seed_) { subset in
                let currentDirPath = "\(path_)/\(String(format: "%04i", i))"
                i += 1
                logger.info("\(subset)")
                // logger.info("\(subset.id2relationship.asOpenKEReversedIdMapping)")
                writeLines("\(currentDirPath)/relation2id.txt", subset.id2relationship.asOpenKEReversedIdMapping, logger: logger)
                writeLines("\(currentDirPath)/entity2id.txt", subset.id2entity.asOpenKEReversedIdMapping, logger: logger)
                // logger.info("\(subset.train.asOpenKETriples)")
                writeLines("\(currentDirPath)/train2id.txt", subset.train.asOpenKETriples, logger: logger)
                writeLines("\(currentDirPath)/test2id.txt", subset.test.asOpenKETriples, logger: logger)
                writeLines("\(currentDirPath)/valid2id.txt", subset.validation.asOpenKETriples, logger: logger)
            }
        }
        // print(String(format: "%04i", 12))

        logger.info("Writing results to '\(path)'")
    }
}
