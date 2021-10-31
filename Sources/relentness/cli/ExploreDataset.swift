import Foundation
import ArgumentParser
import Logging
import wickedData

public struct ExploreDataset: ParsableCommand {
    @Argument(help: "Path to the directory with dataset files")
    var corpus: String

    @Option(name: .shortAndLong, help: "Name of the file with triples specification")
    var model: String = "train2id.txt"

    @Option(name: .shortAndLong, help: "Relationship name to find examples of")
    var relationship: String

    @Option(name: .shortAndLong, help: "Entity name to find examples of")
    var entity: String?

    @Option(name: .shortAndLong, help: "Number of triples to print")
    var n: Int?

    @Flag(name: .shortAndLong, help: "Enably wordy way of logging")
    var verbose = false

    @Flag(name: .long, help: "Enably wordy way of logging")
    var discardExistingLogFile = false

    @Option(name: .shortAndLong, help: "Name of log file")
    var logFileName: String?

    @Argument(help: "Names of files containing indexed triples to consider")
    var batches: [String] = ["train2id"]

    public static var configuration = CommandConfiguration(
        commandName: "explore",
        abstract: "Explore dataset with triples"
    )

    public init() {}

    mutating public func run() {
        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  

        let logger = Logger(level: verbose ? .trace : .info, label: "main")
        
        let importer = OpenKEImporter(corpus, batches: batches)

        do {
            let triples = try importer.searchByRelationAndEntity(relationship, entity: entity, n: n)
            for triple in triples {
                print(
                    "\(triple.head)  --\(triple.relation)-->  \(triple.tail)"
                )
            }
        } catch {
            print(error)
        }
    }
}
