import wickedData

public struct CountableBindingTypeWithReflexiveRelationAggregation: CountableBindingTypeWithAggregation {
    public let count: Variable
    public let loopback: Variable

    static let loopbackRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/loopbackReflexiveRelation")

    public var aggregationTriples: [Triple] {
        let groupNode = makeGroupingNode()

        return [
            try! Triple(NodeType.Entity(loopback.value), CountableBindingTypeWithReflexiveRelationAggregation.loopbackRelation, groupNode, type: .source),
        ]
    }
}

