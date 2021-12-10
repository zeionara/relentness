import Foundation
import Yams

public struct PatternQuery: CustomStringConvertible, Codable, Sendable {
    public static let importFromRegex = try! NSRegularExpression(pattern: "from (?<path>.+)")
    public static let queriesRootPath = "Assets/Patterns/Queries"

    private let configText: String?
    private let configPath: String?

    // public init(from decoder: Decoder) throws {
    //    var values = try decoder.unkeyedContainer()

    //    let configValue = try values.decode(String.self)

    //    print(try! configValue.parse(regex: PatternQuery.importFromRegex, namedRange: "path"))

    //    text = configValue
    // }

    public init(configValue: String) {
        if let path = try? configValue.parse(regex: PatternQuery.importFromRegex, namedRange: "path") {
            self.configPath = path
            // if let contents = try? String(contentsOf: URL.local("\(PatternQuery.queriesRootPath)/\(path)")!, encoding: .utf8) {
            //     self.text = contents
            // } else {
            //     self.text = configValue
            // }
        } else {
            self.configPath = nil
        }
        self.configText = configValue

        // print(getText(name: "compositions"))
    }

    public func getText(name: String) -> String {
        // print("\(PatternQuery.queriesRootPath)/\(name.fromKebabToCamelCase().capitalizingFirstLetter())/\(configPath!)")
        if let path = configPath, let contents = try? String(
            contentsOf: URL.local("\(PatternQuery.queriesRootPath)/\(name.fromKebabToCamelCase().capitalizingFirstLetter())/\(path)")!,
        encoding: .utf8) {
            return contents
        } else {
            return configText ?? configPath!
        }
    }

    public var description: String {
        return configPath ?? configText!
    }
}

extension PatternQuery: ScalarConstructible {
    public static func construct(from scalar: Node.Scalar) -> PatternQuery? {
        // print("Calling initializer inside constructor")
        return PatternQuery(configValue: scalar.string)
    }

    /// Construct an instance of `String`, if possible, from the specified scalar.
    ///
    /// - parameter scalar: The `Node.Scalar` from which to extract a value of type `String`, if possible.
    ///
    /// - returns: An instance of `String`, if one was successfully extracted from the scalar.
    // public static func construct(from scalar: Node.Scalar) -> String? {
    //     return scalar.string
    // }

    /// Construct an instance of `String`, if possible, from the specified `Node`.
    ///
    /// - parameter node: The `Node` from which to extract a value of type `String`, if possible.
    ///
    /// - returns: An instance of `String`, if one was successfully extracted from the node.
    // public static func construct(from node: Node) -> String? {
    //     // This will happen while `Dictionary.flatten_mapping()` if `node.tag.name` was `.value`
    //     if case let .mapping(mapping) = node {
    //         for (key, value) in mapping where key.tag.name == .value {
    //             return construct(from: value)
    //         }
    //     }

    //     return node.scalar?.string
    // }
}
