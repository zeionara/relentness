import ahsheet
import Foundation


public class GoogleSheetsApiAdapter {
    public static let sheetNameDateFormat = "dd-MM-yyyy"
    private static let sheetSuffixSize = 3

    public var nextCell: Address
    public var sessionWrapper: GoogleApiSessionWrapper 
    private var nextSheetId: Int
    private var requests: [GoogleSheetsApiRequest]
    private var nextSheetSuffix: Int? = nil
    private var spreadsheetMetaCache: SpreadsheetMeta? = nil

    public init(sheet: String? = "sheets-adapter-testing", initialSheetId: Int? = nil) throws {
        sessionWrapper = try GoogleApiSessionWrapper()
        nextCell = Address(row: 0, column: 0, sheet: sheet) 
        let spreadsheetMetaCache = try! sessionWrapper.getSpreadsheetMeta()
        self.spreadsheetMetaCache = spreadsheetMetaCache
        self.nextSheetId = initialSheetId ?? (spreadsheetMetaCache.sheets.map{$0.id}.max()! + 1)
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

        let gitRev = try! runSubprocessAndGetOutput(
            path: "/usr/bin/git",
            args: ["rev-parse", "--short", "HEAD"],
            env: [:]
        )!

        let gitBranch = try! runSubprocessAndGetOutput(
            path: "/usr/bin/git",
            args: ["rev-parse", "--abbrev-ref", "HEAD"], // , "|", "grep", "'*'", "|", "cut", "-d", "' '", "-f2"],
            env: [:]
        )!

        let baseTitle = "\(dateString)-\(gitBranch)-\(gitRev)"
        var sheetSuffix: Int = -1

        if let unwrappedSheetSuffix = nextSheetSuffix {
            sheetSuffix = unwrappedSheetSuffix
            nextSheetSuffix = unwrappedSheetSuffix + 1
        } else {

            let titleRegex = try! NSRegularExpression(pattern: "\(baseTitle)-(?<suffix>[0-9]{\(GoogleSheetsApiAdapter.sheetSuffixSize),\(GoogleSheetsApiAdapter.sheetSuffixSize)})")

            let meta = getSpreadsheetMeta() // try! sessionWrapper.getSpreadsheetMeta()

            let existingIds = meta.sheets.map{
                $0.title
            }.filter{
                $0.range(of: titleRegex.pattern, options: .regularExpression) == $0.startIndex..<$0.endIndex
            }.map{
                Int(
                    $0.namedGroup(name: "suffix", regex: titleRegex)
                )!
            }

            if existingIds.count < 1 {
                sheetSuffix = 0
            } else {
                sheetSuffix = existingIds.max()! + 1
            }

            nextSheetSuffix = sheetSuffix + 1
        }

        return "\(baseTitle)-\(String(format: "%0\(GoogleSheetsApiAdapter.sheetSuffixSize)d", sheetSuffix))"
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

    public func appendCells(_ values: [[CellValue]], sheetId: Int? = nil, style: [AppendCells.Row.Value.TextStyle]? = nil, format: Format? = nil) throws -> GoogleSheetsApiAdapter {
        requests.append(
            GoogleSheetsApiRequest.appendCells(
                AppendCells(
                    rows: values.map{row in
                        AppendCells.Row(
                            values: row.map{cell in
                                AppendCells.Row.Value(
                                    userEnteredValue: cell,
                                    textFormatRuns: style,
                                    userEnteredFormat: format
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

    public func getSpreadsheetMeta(forcePull: Bool = false) -> SpreadsheetMeta {
        if let cache = spreadsheetMetaCache, forcePull == false {
            return cache
        } else {
            let cache = try! sessionWrapper.getSpreadsheetMeta()
            spreadsheetMetaCache = cache
            return cache
        }
    }
}

