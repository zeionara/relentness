import Foundation

public struct AddSheet: Codable {
    struct SheetProperties: Codable {
        let title: String
        var tabColor: Color? = nil
        let sheetId: Int
    }

    let properties: SheetProperties
}

public extension GoogleSheetsApiAdapter {
    func addSheet(_ title: String? = nil, id: Int? = nil, tabColor: String? = nil) throws -> GoogleSheetsApiAdapter {
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

    var defaultTitle: String {
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
            args: ["rev-parse", "--abbrev-ref", "HEAD"],
            env: [:]
        )!

        let baseTitle = "\(dateString)-\(gitBranch)-\(gitRev)"
        var sheetSuffix: Int = -1

        if let unwrappedSheetSuffix = nextSheetSuffix {
            sheetSuffix = unwrappedSheetSuffix
            nextSheetSuffix = unwrappedSheetSuffix + 1
        } else {

            let titleRegex = try! NSRegularExpression(pattern: "\(baseTitle)-(?<suffix>[0-9]{\(GoogleSheetsApiAdapter.sheetSuffixSize),\(GoogleSheetsApiAdapter.sheetSuffixSize)})")

            let meta = getSpreadsheetMeta()

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
}

