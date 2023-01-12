import OrderedCollections

struct MetricNode {
    public static let PART_LABEL = "part"
    public static let WHOLE_LABEL = "whole"

    let label: String
    let tree: MetricTree

    init(_ tree: MetricTree, label: String) {
        self.tree = tree
        self.label = label
    }

    init(from bytes: [UInt8], startingAt offset: inout Int) throws {
        // let length = bytes.first!
        // label = "foo"
        // tree = [MetricTree]()

        // let relevantBytes = bytes[offset...]
        // let labelEnd = relevantBytes.firstIndex(of: 0)!

        // print(String(relevantBytes[..<labelEnd].map{code in Character(Unicode.Scalar(code))}))

        (offset, label) = bytes.decode(startingAt: offset)

        // print(label, offset)

        offset += 1 // skip the last byte of the decoded string which is zero

        tree = try MetricTree(from: bytes, startingAt: &offset)
    }

    func collectMeasurements(
        labels: [String],
        measurements collectedMeasurements: inout OrderedDictionary<[String], [Measurement]>,
        metrics collectedMetrics: inout OrderedSet<Evaluator.Metric>,
        transposed transposedMetrics: inout OrderedDictionary<Evaluator.Metric, [Double]>
    ) throws {
        // print(label)
        // print(metrics)
        try tree.collectMeasurements(labels: labels.appending(label), measurements: &collectedMeasurements, metrics: &collectedMetrics, transposed: &transposedMetrics)
        // print(metrics)
    }
}

struct Measurement {
    let metric: Evaluator.Metric
    let value: Double
}

public struct MetricTree {
    enum DescriptionError: Error {
        case missingBothChildsAndMeasurements(atLabels: [String])
        case foundConflictingMeasurements(forLabels: [String])
        case numberOfPartMetricsDoesNotMatch(forLabels: [String])
    }

    var childs: [MetricNode]? = nil
    var measurements: [Measurement]? = nil

    init(_ measurements: Measurement...) {
        self.measurements = measurements
    }

    init(_ childs: MetricNode...) {
        self.childs = childs
    }

    init(from string: String) throws {
        var offset = 0
        try self.init(from: string.bytes, startingAt: &offset)
    }

    init(from bytes: [UInt8], startingAt offset: inout Int) throws {
        let length = bytes[offset]
        // print(length)

        if length & 0x80 > 0 {
            // childs = nil // [MetricNode]()

            let nMetrics = length & 0x7f
            var metricNameOffset = (offset + 8 * Int(nMetrics) + 1)
            var valueOffset = offset + 1

            measurements = try (0..<nMetrics).map { _ in
                defer {
                    // metricNameOffset += 1
                    valueOffset += 8
                }

                // print(bytes[metricNameOffset...])

                let metric = try Evaluator.Metric.decode(from: bytes, startingAt: &metricNameOffset)
                // print(metric)

                return Measurement(
                    metric: metric,
                    value: bytes.decode(startingAt: valueOffset)
                )
            }

            // print(offset, metricNameOffset)
            offset = metricNameOffset

            // print(metrics)
            // let value: Double = bytes.decode(startingAt: offset + 1)
            // print(value)

            // // var metricNameOffset = bytes[(offset + 8 * Int(length & 0x7f) + 1)...]
            // var metricNameOffset = (offset + 8 * Int(length & 0x7f) + 1)

            // let metric = try Evaluator.Metric.decode(from: bytes, startingAt: &metricNameOffset)
            // print(metric)
        } else {
            offset += 1

            // childs = (0..<length).map{ _ in
            childs = try (0..<length).map{ _ in
                try MetricNode(from: bytes, startingAt: &offset)
            }

            // print(offset)

            // print(bytes[offset...])
        }
    }

    func collectMeasurements(
        labels: [String],
        measurements collectedMeasurements: inout OrderedDictionary<[String], [Measurement]>,
        metrics collectedMetrics: inout OrderedSet<Evaluator.Metric>,
        transposed transposedMetrics: inout OrderedDictionary<Evaluator.Metric, [Double]>
    ) throws {
        // print("childs?", childs)

        if let childs = childs {
            try childs.forEach{ node in
                try node.collectMeasurements(labels: labels, measurements: &collectedMeasurements, metrics: &collectedMetrics, transposed: &transposedMetrics)
            }
            return
        }

        // print("no childs")

        guard let measurements = measurements else {
            throw DescriptionError.missingBothChildsAndMeasurements(atLabels: labels)
        }

        if let _ = collectedMeasurements[labels] {
            throw DescriptionError.foundConflictingMeasurements(forLabels: labels)
        }

        collectedMeasurements[labels] = measurements
        // print(transposedMetrics)
        measurements.forEach{ measurement in
            transposedMetrics.append(measurement.value, to: measurement.metric)
        }
        // print(transposedMetrics)
        // collectedMetrics.insert(contentsOf: measurements.map{ $0.metric })
        collectedMetrics.insert(contentsOf: measurements.map{ $0.metric })
    }

    public func describe(accuracy: Int = 5, valueWidth: Int = 16, labelWidth: Int = 32) -> String {
        var collectedMeasurements = OrderedDictionary<[String], [Measurement]>() // [[String]: [Measurement]]()
        var transposedMetrics = OrderedDictionary<Evaluator.Metric, [Double]>()
        var collectedMetrics = OrderedSet<Evaluator.Metric>()

        do {
            try collectMeasurements(labels: [], measurements: &collectedMeasurements, metrics: &collectedMetrics, transposed: &transposedMetrics)
        } catch DescriptionError.missingBothChildsAndMeasurements(let labels) {
            print("Missing both childs and measurements: \(labels)")
        } catch DescriptionError.foundConflictingMeasurements(let labels) {
            print("Found conflicting measurements: \(labels)")
        } catch {
            print("Unexpected error: \(error)")
        }

        var metricLabels = [[String]?]()
        var partRowLength: Int? = nil

        // Suppose that values in every partial entry are located in the same order which corresponds to the order of metrics in the $collectedMetrics
        // The partial metrics are stored first
        var partRows = try! collectedMeasurements.filter{ $0.key.first == MetricNode.PART_LABEL }.map{ (labels, measurements) in
            let row = MetricRow(labels: Array(labels.dropFirst()), values: measurements.values)

            if let partRowLength = partRowLength {
                guard row.count == partRowLength else {
                    throw DescriptionError.numberOfPartMetricsDoesNotMatch(forLabels: labels)
                }
            } else {
                partRowLength = row.count
                metricLabels = row.values.map{ _ in nil }
            }

            return row
        }

        var means = [Double]()
        var stds = [Double]()

        var i = 0

        transposedMetrics.forEach{ (metric, values) in
            if let partRowLength = partRowLength, (i < partRowLength) {
                means.append(values.avg())
                stds.append(values.std())
                i += 1
            }
        }

        partRows.append(MetricRow(labels: ["mean"], values: means))
        partRows.append(MetricRow(labels: ["std"], values: stds))

        let wholeRows = collectedMeasurements.filter{ $0.key.first == MetricNode.WHOLE_LABEL }.map{ (labels, measurements) in
            let row = MetricRow(labels: Array(labels.dropFirst()), values: measurements.values)

            let metricLabel = row.labels.count == 0 ? nil : labels
            // let metricLabel = labels.count == 0 ? nil : labels

            // Suppose that in this nested loop "whole" labels are obesrved in the same sequence as during the $collectedMetrics object construction
            row.values.forEach{_ in metricLabels.append(metricLabel) }
            
            return row
        }

        // print(partRows)
        // print(wholeRows)
        // print(metricLabels)

        // print(String(repeating: " ", count: labelWidth) + MetricHeader(labels: metricLabels, metrics: Array(collectedMetrics)).describe(width: valueWidth))
        let header = String(repeating: " ", count: labelWidth) + MetricHeader(labels: metricLabels, metrics: Array(collectedMetrics)).describe(width: valueWidth)

        // print(partRows.first!.describe(accuracy: 5, valueWidth: 16, labelWidth: 32))

        var isFirstRow = true
        let rows = partRows.map{ row in
            if isFirstRow {
                isFirstRow = false
                return row.describe(accuracy: accuracy, valueWidth: valueWidth, labelWidth: labelWidth, appending: wholeRows)
            } else {
                return row.describe(accuracy: accuracy, valueWidth: valueWidth, labelWidth: labelWidth)
            }
        }.joined(separator: "\n")

        // print(collectedMeasurements.values)
        // print(collectedMetrics)
        // print(transposedMetrics)

        // print(means, stds)

        return "\(header)\n\(rows)"
    }
}
