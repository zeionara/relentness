import Foundation
import ArgumentParser
import Logging
import wickedData

public enum Dataset: String {
    case demo, wordnet_11
}

public struct DatasetImpl {
    public let name: Dataset
    public let path: String

    public var description: String {
        "\(name)@\(path)"
    }
}

let DATASETS_FOR_COMPARISON: [DatasetImpl] = [
    // ModelImpl(architecture: .se, platform: .grapex),
    // ModelImpl(architecture: .transe, platform: .grapex),
    DatasetImpl(name: .demo, path: "Demo/0000"),
    DatasetImpl(name: .wordnet_11, path: "wordnet-11"),
    // ModelImpl(architecture: .complex, platform: .openke)
]

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

    public static var configuration = CommandConfiguration(
        commandName: "compare-datasets",
        abstract: "Evaluate datasets by checking which graph patterns are present in their structure"
    )

    public init() {}

    mutating public func run() {

        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  
        let logger = Logger(level: verbose ? .trace : .info, label: "main")
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

        // print(OpenKEImporter(unwrappedCorpus, batches: batches).asTtls(batchSize: 5).first!)
        BlockingTask {
            let adapter = BlazegraphAdapter(address: blazegraphHost_)
            let patterns = Patterns(patternsPath_)

            for dataset in DATASETS_FOR_COMPARISON {
                logger.info("Evaluating dataset \(dataset.name)...")
                logger.info("Cleaning the knowledge base...")
                let clearResponse = try! await adapter.clear()
                logger.trace(Logger.Message(stringLiteral: String(describing: clearResponse)))
                logger.info("Filling the knowledge base with required data...")
                // OpenKEImporter(unwrappedCorpus, batches: batches).toTtl()
                if let unwrappedBatchSize = batchSize_ {
                    let ttls = OpenKEImporter(dataset.path, batches: batches).asTtls(batchSize: unwrappedBatchSize)
                    logger.trace("Generated \(ttls.count) batches for updating the knowledge base")
                    for i in 0..<ttls.count {
                        logger.trace("Inserting \(i + 1) batch...")
                        let insertResponse = try! await adapter.insert( 
                            InsertQuery(
                                text: ttls[i]
                            ) // ,
                            // timeout: 3_600_000
                        )
                        logger.trace(Logger.Message(stringLiteral: String(describing: insertResponse)))
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
            // }


        // }

        // BlockingTask {
            // let countSymmetricPairs = CountingQuery(
            //     text: """
            //     select (count(?h) as ?count) where {
            //       ?h ?r ?t.
            //       ?t ?r ?h
            //     }
            //     """
            // )

            // let countAsymmetricTriples = CountingQuery(
            //     text: """
            //     select (count(?h) as ?count) where {
            //       ?h ?r ?t.
            //       filter ( !exists { ?t ?r ?h } )
            //     }
            //     """
            // )

            // let adapter = BlazegraphAdapter(address: blazegraphHost_)

            // let nSymmetricTriples = try! await adapter.sample(countSymmetricPairs).count
            // let nAsymmetricTriples = try! await adapter.sample(countAsymmetricTriples).count
            // let nTotalTriples = nSymmetricTriples + nAsymmetricTriples

            // print("\(String(format: "%.3f", Double(nSymmetricTriples) / Double(nTotalTriples))) portion of triples are symmetrical") 

            // print("Handling patterns...")

                logger.info("pattern\t\(PatternStats<CountableBindingTypeWithOneRelationAggregation>.header)")
                for pattern in patterns.storage.elements {
                    switch pattern.name {
                        case "symmetric":
                            let stats: PatternStats<CountableBindingTypeWithOneRelationAggregation> = try! await pattern.evaluate(adapter) 
                            logger.info("symmetric\t\(stats)")
                        case "antisymmetric":
                            let stats: PatternStats<CountableBindingTypeWithAntisymmetricRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            logger.info("antisymmetric\t\(stats)")
                        case "equivalence":
                            let stats: PatternStats<CountableBindingTypeWithEquivalentRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            logger.info("equivalence\t\(stats)")
                        case "implication":
                            let stats: PatternStats<CountableBindingTypeWithImplicationRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            logger.info("implication\t\(stats)")
                        case "reflexive":
                            let stats: PatternStats<CountableBindingTypeWithReflexiveRelationAggregation> = try! await pattern.evaluate(adapter) 
                            logger.info("reflexive\t\(stats)")
                        case "transitive":
                            let stats: PatternStats<CountableBindingTypeWithTransitiveRelationAggregation> = try! await pattern.evaluate(adapter) 
                            logger.info("transitive\t\(stats)")
                        case "composition":
                            let stats: PatternStats<CountableBindingTypeWithCompositionRelationsAggregation> = try! await pattern.evaluate(adapter) 
                            logger.info("composition\t\(stats)")
                        case let patternName:
                            print("Unsupported pattern \(patternName)") 
                    }
                }
            }
            // print("There are \(try! await adapter.sample(countSymmetricPairs).count) symmetric relation pair instances in the knowledge base")
        } // BlockingTask
    }
}

