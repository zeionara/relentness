import Foundation

public struct Path {
    static let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    static let assets = Path.root.appendingPathComponent("Assets")
    static let config = Path.assets.appendingPathComponent("Config")
    static let corpora = Path.assets.appendingPathComponent("Corpora")
    static let log = Path.assets.appendingPathComponent("Log")
}
