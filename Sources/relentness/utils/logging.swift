import Foundation
import Logging


public extension Logger {
    init(level: Logger.Level = .info, label: String) {
        self.init(label: label)
        logLevel = level
    }
}

public struct FileLogHandler: LogHandler {
    private let path: String
    private let label: String
    public var logLevel: Logger.Level

    private var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }

    init(level: Logger.Level?, label: String, path: String) {
        if let unwrappedLevel = level {
            logLevel = unwrappedLevel
        } else {
            logLevel = .info
        }
        self.label = label
        self.path = path
    }

    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        let prettyMetadata = metadata?.isEmpty ?? true ? self.prettyMetadata : self.prettify(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))
        "\(self.timestamp()) \(level) \(label):\(prettyMetadata.map { " \($0)" } ?? "") \(message)\n".append(path)
    }

    private func prettify(_ metadata: Logger.Metadata) -> String? {
        return !metadata.isEmpty ? metadata.map { "\($0)=\($1)" }.joined(separator: " ") : nil
    }

    private func timestamp() -> String {
        var buffer = [Int8](repeating: 0, count: 255)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
}

public func setupLogging(path: String? = nil, verbose: Bool, discardExistingLogFile: Bool) {
    if let pathUnwrapped = path {
        let augmentedPath = "Assets/Logs/\(pathUnwrapped).txt"
        
        makeSureFileExists(augmentedPath, recreate: discardExistingLogFile)
        LoggingSystem.bootstrap{ label in
            MultiplexLogHandler(
                [
                    FileLogHandler(level: verbose ? .trace : .info, label: label, path: augmentedPath),
                    StreamLogHandler.standardOutput(label: label)
                ]
            )
        }
    }
}

