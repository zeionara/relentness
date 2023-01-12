struct MetricRow {
    let labels: [String]
    let values: [Double]

    var count: Int {
        values.count
    }

    func describe(accuracy: Int, valueWidth: Int, labelWidth: Int, withPad padString: String = " ", startingAt padIndex: Int = 0, appending rows: [MetricRow]? = nil) -> String {
        let paddedLabels = labels.joined(separator: " ").padding(toLength: labelWidth, withPad: padString, startingAt: padIndex)

        let paddedValues = values.map{ value in
            value.padding(accuracy: accuracy, toLength: valueWidth, withPad: padString, startingAt: padIndex)
        }.joined()

        if let rows = rows {
            let paddedRows = rows.map{ row in
                row.values.map{ value in
                    value.padding(accuracy: accuracy, toLength: valueWidth, withPad: padString, startingAt: padIndex)
                }.joined()
            }.joined()

            return "\(paddedLabels)\(paddedValues)\(paddedRows)"
        }
        return "\(paddedLabels)\(paddedValues)"
    }
}

struct MetricHeader {
    // enum DescriptionError: Error {
    //     case cannotAlignLabels
    // }

    let labels: [[String]?]
    let metrics: [Evaluator.Metric]

    func describe(width: Int, withPad padString: String = " ", startingAt padIndex: Int = 0) -> String {
        guard labels.count == metrics.count else {
            return metrics.map{ $0.asColumnHeader }.joined()
            // throw DescriptionError.cannotAlignLabels
        }

        return zip(labels, metrics).map{ (labels, metric) in
            if let labels = labels {
                return "\(metric.asColumnHeader)#\(labels.joined(separator: ":"))".padding(toLength: width, withPad: padString, startingAt: padIndex)
            } else {
                return metric.asColumnHeader.padding(toLength: width, withPad: padString, startingAt: 0)
            }
        }.joined()
    }
}
