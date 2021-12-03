// 1. Generate request body (one cell is transformed into one rule - hence there is no complex address processing)

public struct CellEmphasisRule: Codable {
    let range: Range
    var cell: [String: [String: [String: AppendCells.Row.Value.TextFormatRun.TextFormatValue]]] = [
        "userEnteredFormat": [
            "textFormat": [
                "bold": .bool(value: true)
            ]
        ]
    ]
    var fields: String = "userEnteredFormat.textFormat"

    public init(range: Range) {
        self.range = range
    } 

    public init(cell: CellLocation, sheet: Int? = nil) {
        self.range = Range(
            length: 1,
            height: 1,
            offset: cell,
            sheet: sheet
        )
    }
}

// 2. Transform cells into request bodies

public extension GoogleSheetsApiAdapter {
    func emphasizeCells(_ cells: [CellLocation], sheet: Int? = nil) -> GoogleSheetsApiAdapter {
        requests.append(
            contentsOf: cells.asRequests(sheet: sheet)
        )

        return self
    }
}

// 3. Append results to the main requests list

public extension Collection where Element == CellLocation {
    func asRequests(sheet: Int? = nil) -> [GoogleSheetsApiRequest] {
        self.map{
            GoogleSheetsApiRequest.emphasizeCells(
                CellEmphasisRule(cell: $0, sheet: sheet)
            )
        }
    }
}

