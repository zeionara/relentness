import ahsheet

public class GoogleSheetsApiAdapter {
    public var nextCell: Address
    public var sessionWrapper: GoogleApiSessionWrapper 

    public init(sheet: String? = "sheets-adapter-testing") throws {
        sessionWrapper = try GoogleApiSessionWrapper()
        nextCell = Address(row: 0, column: 0, sheet: sheet) 
    }

    public func append(_ data: [[String]]) throws {
        try sessionWrapper.setSheetData(
            SheetData(
                range: nextCell.sendable,
                values: data
            )
        )
        nextCell = Address(row: nextCell.rowIndex + data.count, column: nextCell.columnIndex, sheet: nextCell.sheet)
    }

    public func add_sheet(title: String) throws -> String {
        let result = try sessionWrapper.batchUpdate(
            [[
                "addSheet": [
                    "properties": 
                        [
                            "title": title
                        ]
                ]
            ]]
        )

        return result!.description
    }
}

