let SOFT_RED = try! Color("e67c73")
let SOFT_YELLOW = try! Color("ffd666")
let SOFT_GREEN = try! Color("57bb8a")

public enum DecodingError: Error {
    case unsupportedType(name: String)
}

// 1. Collect ranges

public class MeagerMetricSetFormatRanges {
    private(set) var straightMetricRanges: [Range]
    private(set) var inverseMetricRanges: [Range]
    private(set) var timeRanges: [Range]

    public let sheet: Int?

    public init(sheet: Int? = nil) {
        straightMetricRanges = []
        inverseMetricRanges = []
        timeRanges = []
        self.sheet = sheet
    }

    public func addMeasurements(height: Int, offset: CellLocation) {
        straightMetricRanges.append(
            Range(
                length: 4,
                height: height,
                offset: CellLocation(
                    row: offset.row,
                    column: offset.column + 1 // The first column contains Mean Rank (MR) metric, which should be formatted following inverse rules
                ),
                sheet: sheet
            ) 
        )

        inverseMetricRanges.append(
            Range(
                length: 1,
                height: height,
                offset: CellLocation(
                    row: offset.row,
                    column: offset.column
                ),
                sheet: sheet
            ) 
        )

        timeRanges.append(
            Range(
                length: 3,
                height: height,
                offset: CellLocation(
                    row: offset.row,
                    column: offset.column + 5
                ),
                sheet: sheet
            )
        )
    }

    public var conditionalFormatRules: [ConditionalFormatRule] {
        return [
            ConditionalFormatRule(ranges: straightMetricRanges),
            ConditionalFormatRule(ranges: inverseMetricRanges, inverse: true),
            ConditionalFormatRule(ranges: timeRanges, inverse: true)
        ]
    }
}

// 2. Generate request body

public struct ConditionalFormatRule: Codable {
    public let ranges: [Range]
    public let inverse: Bool
    public let index: Int

    public init(range: Range, index: Int = 0, inverse: Bool = false) {
        ranges = [range]
        self.index = index
        self.inverse = inverse
    }

    public init(ranges: [Range], index: Int = 0, inverse: Bool = false) {
        self.ranges = ranges
        self.index = index
        self.inverse = inverse
    }

    struct Rule: Codable {
        struct GradientRule: Codable {
            struct Point: Codable {
                enum InterpolationPointType: String, Codable {
                    case MIN, MAX, NUMBER, PERCENT, PERCENTILE
                }

                let color: Color
                let type: InterpolationPointType
                var value: String? = nil
            }

            let minpoint: Point
            let midpoint: Point
            let maxpoint: Point
        }

        let gradientRule: GradientRule
        let ranges: [Range]
    }

    enum CodingKeys: String, CodingKey {
        case index
        case rule
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode( 
            Rule(
                gradientRule: Rule.GradientRule(
                    minpoint: Rule.GradientRule.Point(
                        color: inverse ? SOFT_GREEN : SOFT_RED,
                        type: .MIN
                    ),
                    midpoint: Rule.GradientRule.Point(
                        color: SOFT_YELLOW,
                        type: .PERCENTILE,
                        value: "50"
                    ),
                    maxpoint: Rule.GradientRule.Point(
                        color: inverse ? SOFT_RED : SOFT_GREEN,
                        type: .MAX
                    )
                ),
                ranges: ranges
            ),
            forKey: .rule
        )

        try container.encode(index, forKey: .index) 
    }

    public init(from decoder: Decoder) throws {
        throw DecodingError.unsupportedType(name: "ConditionalFormatRule") 
    }
}

// 3. Transform ranges into request body

public extension Collection where Element == ConditionalFormatRule {
    var asRequests: [GoogleSheetsApiRequest] {
        self.map{
            GoogleSheetsApiRequest.addConditionalFormatRule($0)
        }
    }
}

// 4. Append results to the main list of requests

public extension GoogleSheetsApiAdapter {
    func addConditionalFormatRules(_ rules: [ConditionalFormatRule]) -> GoogleSheetsApiAdapter {
        requests.append(
            contentsOf: rules.asRequests
        )

        return self
    }
}

