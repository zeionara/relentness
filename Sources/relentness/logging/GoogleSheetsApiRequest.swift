import Foundation

public enum GoogleSheetsApiRequestError: Error {
    case invalidColor(color: String)
}

public struct Color: Codable {
    static let hexCodeRegex = try! NSRegularExpression(pattern: "#?(?<redBinary>[0-9a-f]{2,2})(?<greenBinary>[0-9a-f]{2,2})(?<blueBinary>[0-9a-f]{2,2})|(?<redSingle>[0-9a-f]{1,1})(?<greenSingle>[0-9a-f]{1,1})(?<blueSingle>[0-9a-f]{1,1})") //TODO: Move to config
    //static let hexCodeRegex = "#?([0-9a-f]{2,2})([0-9a-f]{2,2})([0-9a-f]{2,2})|([0-9a-f]{1,1})([0-9a-f]{1,1})([0-9a-f]{1,1})" //TODO: Move to config

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
            return Double(strtoul(String(hexCode[Range(binaryRange, in: hexCode)!]), nil, 16)) / 255.0
        }
        let singleRange = match.range(withName: "\(name)Single")
        return Double(strtoul(String(hexCode[Range(singleRange, in: hexCode)!]), nil, 16)) / 255.0
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
        hexCode = "cannot infer hexCode from incoming color object" 
    }
}


public struct AddSheet: Codable {
    struct SheetProperties: Codable {
        let title: String
        var tabColor: Color? = nil
        let sheetId: Int
    }

    let properties: SheetProperties
}

public struct AppendCells: Codable {
    struct Row: Codable {
        struct Value: Codable {
            struct UserEnteredValue: Codable {
                var numberValue: Double? = nil
                var stringValue: String? = nil
            }

            let userEnteredValue: UserEnteredValue
        }

        let values: [Value]
    }

    let rows: [Row]
    let sheetId: Int
    var fields: String = "*"
}
    

public enum GoogleSheetsApiRequest: Codable {
    case addSheet(AddSheet)
    case appendCells(AppendCells)

    public func encode(to encoder: Encoder) {
        var container = encoder.singleValueContainer()

        switch self {
            case let .addSheet(addSheetRequest):
                try! container.encode(["addSheet": addSheetRequest])
            case let .appendCells(appendCellsRequest):
                try! container.encode(["appendCells": appendCellsRequest])
        }
    }
}

