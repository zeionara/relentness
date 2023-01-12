enum MetricTreeAggregationError: Error {
    case nodeMismatch(at: String)
    case inconsistentTrees(reason: String)

    case emptyListOfNodes
    case emptyListOfTrees
    case emptyListOfMeasurements

    case cannotAverageNestedTreeList
}

public extension Array where Element == MetricNode {
    func avg() throws -> MetricNode? {
        if self.count < 2 {
            return self.first
        }

        if let referenceNode = self.first {
            guard Set(self.map{ $0.label }).count == 1 else {
                throw MetricTreeAggregationError.nodeMismatch(at: referenceNode.label)
            }
            if let tree = try (self.map{ $0.tree }.avg()) {
                return MetricNode(tree, label: referenceNode.label)
            } else {
                throw MetricTreeAggregationError.emptyListOfTrees
            }
        }

        throw MetricTreeAggregationError.emptyListOfNodes
    }
}

public extension Array where Element == MetricTree {
    func avg() throws -> MetricTree? {
        if self.count < 2 {
            return self.first
        }

        if let referenceTree = self.first {
            if let childs = referenceTree.childs {
                var listsOfChildren = childs.map{ [$0] }

                try self.dropFirst().forEach{ tree in
                    if let childs = tree.childs {
                        var i = 0
                        childs.forEach{ node in
                            listsOfChildren[i].append(node)
                            i += 1
                        }
                    } else {
                        throw MetricTreeAggregationError.inconsistentTrees(reason: "Missing childs")
                    }
                }

                let aggregatedChilds = try listsOfChildren.map{ nodes in
                    if let aggregatedNode = try nodes.avg() {
                        return aggregatedNode
                    }
                    throw MetricTreeAggregationError.emptyListOfNodes
                }

                return MetricTree(aggregatedChilds)
            }

            if let measurements = referenceTree.measurements {
                if measurements.count < 1 {
                    throw MetricTreeAggregationError.emptyListOfMeasurements
                }

                return MetricTree(
                    try measurements.enumerated().map{ (i, referenceMeasurement) in
                        Measurement(
                            metric: referenceMeasurement.metric,
                            value: try self.map{ tree in
                                if let measurements = tree.measurements {
                                    return measurements[i].value
                                } else {
                                    throw MetricTreeAggregationError.inconsistentTrees(reason: "Missing measurements")
                                }
                            }.avg()
                        )
                    }
                )
            }
        }

        return nil
    }
}

public extension Array where Element == Array<MetricTree> {
    func avg() throws -> MetricTree? {
        if let averagedTree = try (self.map{ trees in
            if let averagedTree = try trees.avg() {
                return averagedTree
            }
            throw MetricTreeAggregationError.cannotAverageNestedTreeList
        }.avg()) {
            return averagedTree
        }
        return nil
    }
}
