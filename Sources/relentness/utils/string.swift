import Foundation

public extension Bool {
    var negated: Self { !self }
}

public extension String {
    var rows: [String] {
        self.components(separatedBy: "\n")
    }

    var tabSeparatedValues: [String] {
        self.components(separatedBy: "\t")
    }

    var lastPathComponent: String {
        self.components(separatedBy: "/").last!
    }

    var asDouble: Double {
        Double(self.withoutWhitespaces)!
    }

    var asInt: Int {
        // print("Converting \(self) to int")
        // print(self)
        // print(Int(self))
        // print(Int(String(self)))
        // print(Int("0"))
        // print(self == "0")
        // print(self.count)
        // print("|\(self)|")
        return Int(self.withoutWhitespaces)!
    }

    var withoutWhitespaces: Self {
        filter(\.isWhitespace.negated)
    }
}

public extension String {
    func append(_ url: URL, ensureFileExists: Bool = true) {
        if ensureFileExists {
            makeSureFileExists(url)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            // convert your string to data or load it from another resource
            // let str = "Line 1\nLine 2\n"
            let textData = Data(self.utf8)
            // append your text to your text file
            fileHandle.write(textData)
            // close it when done
            fileHandle.closeFile()
            // testing/reading the file edited
            // if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
            //     print(text)  // "Hello World\nLine 1\nLine 2\n\n"
            // }
        } catch {
            print("Cannot append to file due to exception \(error)")
        }    
    }

    func append(_ path: String, ensureFileExists: Bool = true) {
        // print(path)
        if ensureFileExists {
            makeSureFileExists(path)
        } 
        
        if let url = URL.local(path) {
            append(url, ensureFileExists: false)
        } else {
            print("Cannot write to file \(path) because of invalid url")
        }
    }

    func namedGroup(name: String, regex: NSRegularExpression) -> String {
        return String(
            self[
                Swift.Range(
                    regex.matches(
                        in: self,
                        range: NSRange(
                            self.startIndex..<self.endIndex,
                            in: self
                        )
                    ).first!.range(
                        withName: name
                    ),
                    in: self
                )!
            ]
        )
    }
}

public extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    func fromKebabToCamelCase(with separator: Character = "-") -> String {
        return self.lowercased()
            .split(separator: separator)
            .enumerated()
            .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
            .joined()
    }

    fileprivate func processCamelCaseRegex(pattern: String, sep separator: String) -> String? {
      let regex = try? NSRegularExpression(pattern: pattern, options: [])
      let range = NSRange(location: 0, length: count)
      return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1\(separator)$2")
    }

    func fromCamelCaseToSnakeCase(sep separator: String = "_") -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let fullWordsPattern = "([a-z])([A-Z]|[0-9])"
        let digitsFirstPattern = "([0-9])([A-Z])"
        return self.processCamelCaseRegex(pattern: acronymPattern, sep: separator)?
          .processCamelCaseRegex(pattern: fullWordsPattern, sep: separator)?
          .processCamelCaseRegex(pattern:digitsFirstPattern, sep: separator)?.lowercased() ?? self.lowercased()
    }

    func fromCamelCaseToKebabCase() -> String {
        return fromCamelCaseToSnakeCase(sep: "-")
    }

    var atom: String {
        return ":\(self)"
    }
}

public extension String {
    static let yaml_extension = "yml"

    func append(extension ext: String) -> String {
        return "\(self).\(ext)"
    }

    var yaml: String {
        return append(extension: String.yaml_extension)
    }
}

public extension String {
    func appendingPathComponent(_ component: String) -> String {
        return URL(string: self)!.appendingPathComponent(component).path
    }
}

public enum StringDecodingError: Error {
    case cannotConvertToByte(character: Unicode.Scalar)
}

public extension String {
    static let maxByteValue = 255

    var bytes: [UInt8] {
        get throws {
            let bytes = try self.unicodeScalars.map{ character in
                let value = character.value

                if value > String.maxByteValue {
                    throw StringDecodingError.cannotConvertToByte(character: character)
                }

                return UInt8(value)
            }

            if bytes.count > 1 {
                return bytes.dropLast()
            }
            return bytes
        }
    }
}
