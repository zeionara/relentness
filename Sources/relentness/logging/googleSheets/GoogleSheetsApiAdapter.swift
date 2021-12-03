import ahsheet
import Foundation
import Logging

public class GoogleSheetsApiAdapter {
    public static let sheetNameDateFormat = "dd-MM-yyyy"
    static let sheetSuffixSize = 3

    // public var nextCell: Address
    public var sessionWrapper: GoogleApiSessionWrapper 
    var nextSheetId: Int
    var requests: [GoogleSheetsApiRequest]
    var nextSheetSuffix: Int? = nil
    private var spreadsheetMetaCache: SpreadsheetMeta? = nil

    public init(sheet: String? = "sheets-adapter-testing", initialSheetId: Int? = nil) throws {
        sessionWrapper = try GoogleApiSessionWrapper()
        // nextCell = Address(row: 0, column: 0, sheet: sheet) 
        let spreadsheetMetaCache = try! sessionWrapper.getSpreadsheetMeta()
        self.spreadsheetMetaCache = spreadsheetMetaCache
        self.nextSheetId = initialSheetId ?? (spreadsheetMetaCache.sheets.map{$0.id}.max()! + 1)
        self.requests = [GoogleSheetsApiRequest]()
    }

    // public func append(_ data: [[String]]) throws {
    //     try sessionWrapper.setSheetData(
    //         SheetData(
    //             range: nextCell.sendable,
    //             values: data
    //         )
    //     )
    //     nextCell = Address(row: nextCell.rowIndex + data.count, column: nextCell.columnIndex, sheet: nextCell.sheet)
    // }

    public var lastSheetId: Int {
        nextSheetId - 1
    }

    public func commit(dryRun: Bool = false, logger: Logger? = nil) async throws -> Data? {
        let encodedRequest = try JSONEncoder().encode(["requests": requests])

        if dryRun {
            logger.trace("Generated request:")
            logger.trace(
                // Logger.Message(stringLiteral: 
                String(
                    data: encodedRequest,
                    encoding: .utf8
                )!
                // )
            )

            return nil
        }

        return try sessionWrapper.batchUpdate(
            encodedRequest
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

