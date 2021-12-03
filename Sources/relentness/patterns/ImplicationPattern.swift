import wickedData

public struct CountableBindingTypeWithImplicationRelationsAggregation: CountableBindingTypeWithAggregation {
    public let count: Variable
    public let original: Variable
    public let derivative: Variable

    static let originalRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/originalImplicationRelation")
    static let derivativeRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/derivativeImplicationRelation")

    public var aggregationTriples: [Triple] {
        let groupNode = makeGroupingNode()

        return [
            try! Triple(NodeType.Entity(original.value), CountableBindingTypeWithImplicationRelationsAggregation.originalRelation, groupNode, type: .source),
            try! Triple(NodeType.Entity(derivative.value), CountableBindingTypeWithImplicationRelationsAggregation.derivativeRelation, groupNode, type: .source)
        ]
    }
}

