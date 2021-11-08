import Foundation
import ArgumentParser
import Logging
import wickedData

public struct EvaluateDataset: ParsableCommand {
    @Argument(help: "Path to the directory with dataset files")
    var corpus: String?

    @Flag(name: .shortAndLong, help: "Enable wordy way of logging")
    var verbose = false

    @Flag(name: .long, help: "Enably wordy way of logging")
    var discardExistingLogFile = false

    @Option(name: .shortAndLong, help: "Name of log file")
    var logFileName: String?

    @Option(name: .shortAndLong, help: "Name of file with patten definitions")
    var patternsPath: String

    @Option(name: .shortAndLong, help: "Number of statements per query for updating the knowledge base")
    var batchSize: Int?

    @Flag(name: .long, help: "Include triples from the test batch into the evaluation process")
    var testSubset = false

    @Flag(name: .long, help: "Include triples from the validation batch into the evaluation process")
    var validationSubset = false

    public static var configuration = CommandConfiguration(
        commandName: "deval",
        abstract: "Evaluate dataset by checking which graph patterns are present in its' structure"
    )

    public init() {}

    mutating public func run() {

        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  
        let logger = Logger(level: verbose ? .trace : .info, label: "main")
        
        if let unwrappedCorpus = corpus {
            var batches = ["train2id"]

            if testSubset {
                batches.append("test2id")
            }

            if validationSubset {
                batches.append("valid2id")
            }

            let batchSize_ = batchSize

            // print(OpenKEImporter(unwrappedCorpus, batches: batches).asTtls(batchSize: 5).first!)
            BlockingTask {
                // OpenKEImporter(unwrappedCorpus, batches: batches).toTtl()
                if let unwrappedBatchSize = batchSize_ {
                    let ttls = OpenKEImporter(unwrappedCorpus, batches: batches).asTtls(batchSize: unwrappedBatchSize)
                    print("Generated \(ttls.count) batches for updating the knowledge base")
                    for i in 0..<ttls.count {
                        print("Inserting \(i + 1) batch...")
                        print(
                            try! await BlazegraphAdapter(address: "25.109.46.115").update( 
                                UpdateQuery(
                                    text: ttls[i]
                                ) // ,
                                // timeout: 3_600_000
                            )
                        )
                    }
                    print("Finished knowledge base update")
                } else {
                    print(
                        try! await BlazegraphAdapter(address: "25.109.46.115").update(
                            UpdateQuery(
                                text: OpenKEImporter(unwrappedCorpus, batches: batches).asTtl
                            ),
                            timeout: 3_600_000
                        )
                    )
                }
            }

            // print("Updated \(response.nModifiedTriples) in \(response.executionTimeInMilliseconds) ms")
        }

        let patterns = Patterns(patternsPath)


        BlockingTask {
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

            let adapter = BlazegraphAdapter(address: "25.109.46.115")

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
            // print("There are \(try! await adapter.sample(countSymmetricPairs).count) symmetric relation pair instances in the knowledge base")
        }
    }
}

