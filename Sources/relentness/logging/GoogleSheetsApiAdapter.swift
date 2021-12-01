import ahsheet
import Foundation

public class GoogleSheetsApiAdapter {
    public static let sheetNameDateFormat = "dd-MM-yyyy"

    public var nextCell: Address
    public var sessionWrapper: GoogleApiSessionWrapper 
    private var nextSheetId: Int
    private var requests: [GoogleSheetsApiRequest]

    public init(sheet: String? = "sheets-adapter-testing", initialSheetId nextSheetId: Int = 17) throws {
        sessionWrapper = try GoogleApiSessionWrapper()
        nextCell = Address(row: 0, column: 0, sheet: sheet) 
        self.nextSheetId = nextSheetId
        self.requests = [GoogleSheetsApiRequest]()
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

    public var defaultTitle: String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = GoogleSheetsApiAdapter.sheetNameDateFormat

        let date = Date()
        let dateString = dateFormatter.string(from: date)

        let git_rev = try! runSubprocessAndGetOutput(
            path: "/usr/bin/git",
            args: ["rev-parse", "--short", "HEAD"],
            env: [:]
        )!

        let git_branch = try! runSubprocessAndGetOutput(
            path: "/usr/bin/git",
            args: ["rev-parse", "--abbrev-ref", "HEAD"], // , "|", "grep", "'*'", "|", "cut", "-d", "' '", "-f2"],
            env: [:]
        )!

        return "\(dateString)-\(git_branch)-\(git_rev)"
    }

    public func addSheet(_ title: String? = nil, id: Int? = nil, tabColor: String? = nil) throws -> GoogleSheetsApiAdapter {
        var sheetId = 0

        if let idUnwrapped = id {
            sheetId = idUnwrapped
            nextSheetId = sheetId + 1
        } else {
            sheetId = nextSheetId
            nextSheetId += 1
        }

        let color = tabColor == nil ? nil : try Color(tabColor!)

        requests.append(
            GoogleSheetsApiRequest.addSheet(
                AddSheet(
                    properties: AddSheet.SheetProperties(
                        title: title ?? defaultTitle,
                        tabColor: color,
                        sheetId: sheetId
                    )
                )
            )
        )

        return self
    }

    public func appendCells(_ values: [[CellValue]], sheetId: Int? = nil) throws -> GoogleSheetsApiAdapter {
        requests.append(
            GoogleSheetsApiRequest.appendCells(
                AppendCells(
                    rows: values.map{row in
                        AppendCells.Row(
                            values: row.map{cell in
                                AppendCells.Row.Value(
                                    userEnteredValue: cell
                                )
                            }
                        )
                    },
                    sheetId: sheetId ?? nextSheetId - 1
                )
                )
            )

        return self
    }

    // public func add_sheet(title: String) throws -> String {
    //     let result = try sessionWrapper.batchUpdate(
    //         [[
    //             "addSheet": [
    //                 "properties": 
    //                     [
    //                         "title": title
    //                     ]
    //             ]
    //         ]]
    //     )

    //     return result!.description
    // }

    public func commit(dryRun: Bool = false) async throws -> Data? {
        // let addSheetRequest = GoogleSheetsApiRequest.addSheet(
        //     AddSheet(
        //         properties: AddSheet.SheetProperties(
        //             title: "new-sheet",
        //             tabColor: try! Color(
        //                "#00ff00" 
        //             ),
        //             sheetId: 17
        //         )
        //     )
        // )

        // let appendDataRequest = GoogleSheetsApiRequest.appendCells(
        //     AppendCells(
        //         rows: [
        //             AppendCells.Row(
        //                 values: [
        //                     AppendCells.Row.Value(
        //                         userEnteredValue: CellValue.string("foo")
        //                     ),
        //                     AppendCells.Row.Value(
        //                         userEnteredValue: CellValue.number(1.0)
        //                     )
        //                 ]
        //             )
        //         ],
        //         sheetId: 23
        //     )
        // )

        if dryRun {
            print(
                String(
                    data: try JSONEncoder().encode(["requests": requests]),
                    encoding: .utf8
                )!
            )

            print("bar")

            return nil
        }

        return try sessionWrapper.batchUpdate(
            try JSONEncoder().encode(["requests": requests])
        )
    }
}

