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

        // let logger = Logger(level: verbose ? .trace : .info, label: "main")
        
        if let unwrappedCorpus = corpus {
            var batches = ["train2id"]

            if testSubset {
                batches.append("test2id")
            }

            if validationSubset {
                batches.append("valid2id")
            }

            BlockingTask {
                print(
                    try! await BlazegraphAdapter().update(
                        UpdateQuery(
                            text: OpenKEImporter(unwrappedCorpus, batches: batches).asTtl
                        )
                    )
                )
            }

            // print("Updated \(response.nModifiedTriples) in \(response.executionTimeInMilliseconds) ms")
        }

        BlockingTask {
            let countSymmetricPairs = CountingQuery(
                text: """
                select (count(?h) as ?count) where {
                  ?h ?r ?t.
                  ?t ?r ?h
                }
                """
            )

            let countAsymmetricTriples = CountingQuery(
                text: """
                select (count(?h) as ?count) where {
                  ?h ?r ?t.
                  filter ( !exists { ?t ?r ?h } )
                }
                """
            )

            let adapter = BlazegraphAdapter()

            let nSymmetricTriples = try! await adapter.sample(countSymmetricPairs).count
            let nAsymmetricTriples = try! await adapter.sample(countAsymmetricTriples).count
            let nTotalTriples = nSymmetricTriples + nAsymmetricTriples

            print("\(String(format: "%.3f", Double(nSymmetricTriples) / Double(nTotalTriples))) portion of triples are symmetrical") 
            // print("There are \(try! await adapter.sample(countSymmetricPairs).count) symmetric relation pair instances in the knowledge base")
        }
    }
}

