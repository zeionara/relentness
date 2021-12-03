public typealias CellLocation = (row: Int, column: Int)

public struct Range: Codable {
    public let start: CellLocation
    public let end: CellLocation
    public let sheet: Int?

    public init(length: Int, height: Int, offset: CellLocation = (row: 0, column: 0), sheet: Int? = nil) {
        start = CellLocation(row: offset.row, column: offset.column)
        end = CellLocation(row: offset.row + height, column: offset.column + length) 
        self.sheet = sheet
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CustomCodingkeys.self)

        if let unwrappedSheet = sheet {
            try container.encode(unwrappedSheet, forKey: .sheetId)
        }
        try container.encode(start.row, forKey: .startRowIndex)
        try container.encode(start.column, forKey: .startColumnIndex)
        try container.encode(end.row, forKey: .endRowIndex)
        try container.encode(end.column, forKey: .endColumnIndex)
    }

    private enum CustomCodingkeys: String, CodingKey {
        case sheetId
        case startRowIndex
        case endRowIndex
        case startColumnIndex
        case endColumnIndex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CustomCodingkeys.self)

        start = CellLocation(
            row: try container.decode(Int.self, forKey: .startRowIndex),
            column: try container.decode(Int.self, forKey: .startColumnIndex)
        )

        end = CellLocation(
            row: try container.decode(Int.self, forKey: .endRowIndex),
            column: try container.decode(Int.self, forKey: .endColumnIndex)
        )

        sheet = try? container.decode(Int.self, forKey: .sheetId)
    }
}

