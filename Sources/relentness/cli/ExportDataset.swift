import Foundation
import ArgumentParser
import Logging
import wickedData

public struct ExportDataset: ParsableCommand {
    @Argument(help: "Path to the directory with dataset files")
    var corpus: String

    @Flag(name: .shortAndLong, help: "Enable wordy way of logging")
    var verbose = false

    @Flag(name: .long, help: "Enably wordy way of logging")
    var discardExistingLogFile = false

    @Option(name: .shortAndLong, help: "Name of log file")
    var logFileName: String?

    @Argument(help: "Names of files containing indexed triples to consider")
    var batches: [String] = ["train2id", "test2id", "valid2id"]

    @Option(name: .shortAndLong, help: "Path to the output file")
    var output: String?

    public static var configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export dataset to another format"
    )

    public init() {}

    mutating public func run() {
        setupLogging(path: logFileName, verbose: verbose, discardExistingLogFile: discardExistingLogFile)  

        let logger = Logger(level: verbose ? .trace : .info, label: "main")
        
        let importer = OpenKEImporter(corpus, batches: batches)

        importer.toTtl(output)
        // print(importer.asTtl)
    }
}
