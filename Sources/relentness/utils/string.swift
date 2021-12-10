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
}

