struct MetricNode {
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
}

struct Measurement {
    let metric: Evaluator.Metric
    let value: Double
}

public struct MetricTree {
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
            childs = [MetricNode]()

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
}
