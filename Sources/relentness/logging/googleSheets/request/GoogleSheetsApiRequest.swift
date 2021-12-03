import Foundation

public enum GoogleSheetsApiRequest: Codable {
    case addSheet(AddSheet)
    case appendCells(AppendCells)
    case addConditionalFormatRule(ConditionalFormatRule)
    case repeatCell(NumberFormatRule)
    case emphasizeCells(CellEmphasisRule)

    public func encode(to encoder: Encoder) {
        var container = encoder.singleValueContainer()

        switch self {
            case let .addSheet(addSheetRequest):
                try! container.encode(["addSheet": addSheetRequest])
            case let .appendCells(appendCellsRequest):
                try! container.encode(["appendCells": appendCellsRequest])
            case let .addConditionalFormatRule(addFormatRuleRequest):
                try! container.encode(["addConditionalFormatRule": addFormatRuleRequest])
            case let .repeatCell(repeatCell):
                try! container.encode(["repeatCell": repeatCell])
            case let .emphasizeCells(emphasizeCell):
                try! container.encode(["repeatCell": emphasizeCell])
        }
    }
}

