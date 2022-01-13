import Foundation

public enum RegexMatchError: Error {
    case givenStringDoesNotMatchPattern(string: String, pattern: String)
    case argumentError(comment: String)
}

public extension String {
    func parse(regex: NSRegularExpression, namedRange: String) throws -> String? {
        let fullRange = startIndex..<endIndex

        if let match = range(of: regex.pattern, options: .regularExpression), fullRange == match {
            let regex = try! NSRegularExpression(pattern: regex.pattern)

            let firstMatch = regex.matches(
                in: self,
                range: NSRange(
                    fullRange,
                    in: self
                )
            ).first!

            let valueRange = firstMatch.range(withName: namedRange)

            return String(
                self[
                    Swift.Range(
                        valueRange,
                        in: self
                    )!
                ]
            )
        } else {
            throw RegexMatchError.givenStringDoesNotMatchPattern(string: self, pattern: regex.pattern)
        }
    }

    func parse(pattern: String, namedRange: String) throws -> String? {
        return try parse(regex: NSRegularExpression(pattern: pattern), namedRange: namedRange)
    }

    // func parse(regex: NSRegularExpression, namedRange: String) throws -> String? {
    //     return try parse(regex: regex, namedRange: namedRange)
    // }

    // func parse(pattern: String? = nil, regex: NSRegularExpression? = nil, namedRange: String) throws -> String? {
    //     if let unwrappedPattern = pattern, regex == nil {
    //         return try parse(regex: NSRegularExpression(pattern: unwrappedPattern), namedRange: namedRange)
    //     } else if let unwrappedRegex = regex, pattern == nil {
    //         return try parse(regex: unwrappedRegex, namedRange: namedRange)
    //     } else if let _ = pattern, let _ = regex {
    //         throw RegexMatchError.argumentError(comment: "Either pattern either regex must be provided but not both")
    //     }
    //     throw RegexMatchError.argumentError(comment: "Either pattern either regex must be provided")
    // }
}
