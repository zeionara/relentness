import ahsheet
import Foundation
import Logging
import OAuth2

public class GoogleSheetsApiAdapter {
    public static let sheetNameDateFormat = "dd-MM-yyyy"
    static let sheetSuffixSize = 3

    // public var nextCell: Address
    public var sessionWrapper: GoogleApiSessionWrapper 
    var nextSheetId: Int
    var requests: [GoogleSheetsApiRequest]
    var nextSheetSuffix: Int? = nil
    private var spreadsheetMetaCache: SpreadsheetMeta? = nil
    private var telegramBot: TelegramAdapter? = nil

    public init(sheet: String? = "sheets-adapter-testing", initialSheetId: Int? = nil, telegramBot: TelegramAdapter? = nil) throws {
        sessionWrapper = try! GoogleSheetsApiAdapter.makeSessionWrapper(telegramBot: telegramBot)
        // nextCell = Address(row: 0, column: 0, sheet: sheet) 
        let spreadsheetMetaCache = try! GoogleSheetsApiAdapter.fetchMeta(sessionWrapper, telegramBot: telegramBot)
        self.spreadsheetMetaCache = spreadsheetMetaCache
        self.nextSheetId = initialSheetId ?? (spreadsheetMetaCache.sheets.map{$0.id}.max()! + 1)
        self.requests = [GoogleSheetsApiRequest]()
        self.telegramBot = telegramBot
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

        return try GoogleSheetsApiAdapter.batchUpdate(
            sessionWrapper,
            telegramBot: telegramBot,
            request: encodedRequest
        )
    }

    private static func makeTelegramNotificationCallback(_ bot: TelegramAdapter) -> BrowserTokenProvider.SignInCallback {
        return { url in
            bot.broadcast("Please, update token using this [url](\(String(describing: url!)))")
        }
    }

    private static func fetchMeta(_ sessionWrapper: GoogleApiSessionWrapper, telegramBot: TelegramAdapter? = nil) throws -> SpreadsheetMeta {
        if let bot = telegramBot {
            return try sessionWrapper.getSpreadsheetMeta(callback: makeTelegramNotificationCallback(bot))
        } else {
            return try sessionWrapper.getSpreadsheetMeta()
        }
    }

    private static func batchUpdate(_ sessionWrapper: GoogleApiSessionWrapper, telegramBot: TelegramAdapter? = nil, request: Data) throws -> Data? {
        if let bot = telegramBot {
            return try sessionWrapper.batchUpdate(request, callback: makeTelegramNotificationCallback(bot))
        } else {
            return try sessionWrapper.batchUpdate(request)
        }
    }

    private static func makeSessionWrapper(telegramBot: TelegramAdapter? = nil) throws -> GoogleApiSessionWrapper {
        if let bot = telegramBot {
            return try GoogleApiSessionWrapper(callback: makeTelegramNotificationCallback(bot))
        } else {
            return try GoogleApiSessionWrapper()
        }
    }

    public func getSpreadsheetMeta(forcePull: Bool = false) -> SpreadsheetMeta {
        if let cache = spreadsheetMetaCache, forcePull == false {
            return cache
        } else {
            let cache = try! GoogleSheetsApiAdapter.fetchMeta(sessionWrapper, telegramBot: telegramBot)
            spreadsheetMetaCache = cache
            return cache
        }
    }
}

