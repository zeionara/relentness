import Foundation

public enum GoogleSheetsApiRequestError: Error {
    case invalidColor(color: String)
}

public struct Color: Codable {
    static let hexCodeRegex = try! NSRegularExpression(
        pattern: "#?(?<redBinary>[0-9a-f]{2,2})(?<greenBinary>[0-9a-f]{2,2})(?<blueBinary>[0-9a-f]{2,2})|(?<redSingle>[0-9a-f]{1,1})(?<greenSingle>[0-9a-f]{1,1})(?<blueSingle>[0-9a-f]{1,1})"
    ) //TODO: Move to config

    let red: Double
    let green: Double
    let blue: Double
    let hexCode: String
    let alpha: Double

    private enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    private static func decodeComponent(match: NSTextCheckingResult, hexCode: String, name: String) -> Double {
        let binaryRange = match.range(withName: "\(name)Binary")
        if binaryRange.lowerBound < binaryRange.upperBound {
            return Double(strtoul(String(hexCode[Swift.Range(binaryRange, in: hexCode)!]), nil, 16)) / 255.0
        }
        let singleRange = match.range(withName: "\(name)Single")
        return Double(strtoul(String(hexCode[Swift.Range(singleRange, in: hexCode)!]), nil, 16)) / 15.0
    }

    public init(_ hexCode: String, alpha: Double = 1.0) throws {
        let hexCodeCharsRange = hexCode.startIndex..<hexCode.endIndex
        if let match = hexCode.range(of: Color.hexCodeRegex.pattern, options: .regularExpression), hexCodeCharsRange == match {
            let firstMatch = Color.hexCodeRegex.matches(
                in: hexCode,
                range: NSRange(
                    hexCodeCharsRange,
                    in: hexCode
                )
            ).first!

            red = Color.decodeComponent(match: firstMatch, hexCode: hexCode, name: "red")
            green = Color.decodeComponent(match: firstMatch, hexCode: hexCode, name: "green")
            blue = Color.decodeComponent(match: firstMatch, hexCode: hexCode, name: "blue")

            self.hexCode = hexCode
            self.alpha = alpha
        } else {
            throw GoogleSheetsApiRequestError.invalidColor(color: hexCode)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        red = try container.decode(Double.self, forKey: .red)
        green = try container.decode(Double.self, forKey: .green)
        blue = try container.decode(Double.self, forKey: .blue)
        alpha = try container.decode(Double.self, forKey: .alpha)
        hexCode = "cannot infer hexCode from incoming color object" // TODO: Implement decoding
    }
}

