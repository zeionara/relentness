public struct Color: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double = 1.0
}

public struct SheetProperties: Codable {
    let title: String
    let tabColor: Color
}

public struct AddSheet: Codable {
    let properties: SheetProperties
}

public struct AppendCells: Codable {
    struct Row: Codable {
        struct Value: Codable {
            struct UserEnteredValue: Codable {
                var numberValue: Double? = nil
                var stringValue: String? = nil
            }

            let userEnteredValue: UserEnteredValue
        }

        let values: [Value]
    }

    let rows: [Row]
}
    

public enum GoogleSheetsApiRequest: Codable {
    case addSheet(AddSheet)
    case appendCells(AppendCells)

    public func encode(to encoder: Encoder) {
        var container = encoder.singleValueContainer()

        switch self {
            case let .addSheet(addSheetRequest):
                try! container.encode(addSheetRequest)
            case let .appendCells(appendCellsRequest):
                try! container.encode(appendCellsRequest)
        }
    }
}

