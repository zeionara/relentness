// 1. Collect ranges

public class MeagerMetricSetNumberFormatRanges {
    private(set) var ranges: [Range]

    public let sheet: Int?

    public init(sheet: Int? = nil) {
        ranges = []
        self.sheet = sheet
    }

    public func addMeasurements(height: Int, offset: CellLocation) {
        ranges.append(
            Range(
                length: 8,
                height: height,
                offset: offset,
                sheet: sheet
            )
        )
    }

    public var numberFormatRules: [NumberFormatRule] {
        ranges.map{NumberFormatRule(range: $0)}
    }
}

public class DatasetCompatisonNumberFormatRanges {
    private(set) var ranges: [Range]

    public let sheet: Int?

    public init(sheet: Int? = nil) {
        ranges = []
        self.sheet = sheet
    }

    public func addMeasurements(height: Int, offset: CellLocation) {
        ranges.append(
            Range(
                length: 9,
                height: height,
                offset: offset,
                sheet: sheet
            )
        )
    }

    public var numberFormatRules: [NumberFormatRule] {
        ranges.map{NumberFormatRule(range: $0)}
    }
}

// 2. Generate request body

public struct NumberFormatRule: Codable {
    let range: Range
    var cell: [String: [String: [String: String]]] = [
        "userEnteredFormat": [
            "numberFormat": [
                "type": "NUMBER",
                "pattern": "0.\(Array(repeating: "0", count: N_DECIMAL_PLACES).joined())"
            ]
        ]
    ]
    var fields: String = "userEnteredFormat.numberFormat"

    public init(range: Range) {
        self.range = range
    } 
}

// 3. Transform ranges into request body

public extension Collection where Element == NumberFormatRule {
    var asRequests: [GoogleSheetsApiRequest] {
        self.map{
            GoogleSheetsApiRequest.repeatCell($0)
        }
    }
}

// 4. Append results to the main list of requests

public extension GoogleSheetsApiAdapter {
    func addNumberFormatRules(_ rules: [NumberFormatRule]) -> GoogleSheetsApiAdapter {
        requests.append(
            contentsOf: rules.asRequests
        )
        
        return self
    }
}

