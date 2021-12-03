public typealias CellValue = AppendCells.Row.Value.UserEnteredValue
public typealias Format = AppendCells.Row.Value.CellFormat

public struct AppendCells: Codable {
    public struct Row: Codable {
        public struct Value: Codable {
            public enum UserEnteredValue: Codable {
                case number(value: Double)
                case string(value: String) 
                case bool(value: Bool) 

                public func encode(to encoder: Encoder) {
                    var container = encoder.singleValueContainer()

                    switch self {
                        case let .number(value):
                            try! container.encode(["numberValue": value])
                        case let .string(value):
                            try! container.encode(["stringValue": value])
                        case let .bool(value):
                            try! container.encode(["boolValue": value])
                    }
                }
            }

            public struct TextFormatRun: Codable { // TODO: Make this structure more reusable
                public enum TextFormatValue: Codable {
                    case number(value: Double)
                    case string(value: String)
                    case bool(value: Bool)
                    case color(value: Color)

                    public func encode(to encoder: Encoder) {
                        var container = encoder.singleValueContainer()

                        switch self {
                        case let .number(value):
                            try! container.encode(value)
                        case let .string(value):
                            try! container.encode(value)
                        case let .bool(value):
                            try! container.encode(value)
                        case let .color(value):
                            try! container.encode(value)
                        }
                    }
                }

                public var format: [String: TextFormatValue]
                public var startIndex: Int? = nil
            }

            public enum TextStyle: Codable {
                case bold

                public func encode(to encoder: Encoder) {
                    var container = encoder.singleValueContainer()

                    switch self {
                        case .bold:
                            try! container.encode(
                                TextFormatRun(
                                    format: ["bold": .bool(value: true)],
                                    startIndex: 0
                                )
                            )
                    }

                }
            }

            public struct CellFormat: Codable {
                public var textFormat: [String: TextFormatRun.TextFormatValue]
            }

            let userEnteredValue: UserEnteredValue
            var textFormatRuns: [TextStyle]? = nil
            var userEnteredFormat: CellFormat? = nil
        }

        let values: [Value]
    }

    let rows: [Row]
    let sheetId: Int
    var fields: String = "*"
}

public extension GoogleSheetsApiAdapter {
    func appendCells(_ values: [[CellValue]], sheetId: Int? = nil, style: [AppendCells.Row.Value.TextStyle]? = nil, format: FormatWrapper? = nil) throws -> GoogleSheetsApiAdapter {
        requests.append(
            GoogleSheetsApiRequest.appendCells(
                AppendCells(
                    rows: values.map{row in
                        AppendCells.Row(
                            values: row.map{cell in
                                AppendCells.Row.Value(
                                    userEnteredValue: cell,
                                    textFormatRuns: style,
                                    userEnteredFormat: format?.decoded
                                )
                            }
                        )
                    },
                    sheetId: sheetId ?? lastSheetId
                )
            )
        )

        return self
    }

    enum FormatWrapper {
        case bold
        case boldRed

        public var decoded: Format {
            switch self {
                case .bold:
                    return Format(
                        textFormat: [
                            "bold": .bool(value: true)
                        ]
                    )
                case .boldRed:
                    return Format(
                        textFormat: [
                            "bold": .bool(value: true),
                            "foregroundColor": .color(value: try! Color("f00"))
                        ]
                    )
            }
        }
    }
}

