import wickedData

public struct CountableBindingTypeWithEquivalentRelationsAggregation: CountableBindingTypeWithAggregation {
    public let count: Variable
    public let primary: Variable
    public let secondary: Variable?

    static let primaryRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/primaryEquivalenceRelation")
    static let secondaryRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/secondaryEquivalenceRelation")

    public var aggregationTriples: [Triple] {
        let groupNode = makeGroupingNode()

        var triples = [
            try! Triple(NodeType.Entity(primary.value), CountableBindingTypeWithEquivalentRelationsAggregation.primaryRelation, groupNode, type: .source)
        ]

        if let unwrappedSecondaryRelation = secondary {
            triples.append(
                try! Triple(NodeType.Entity(unwrappedSecondaryRelation.value), CountableBindingTypeWithEquivalentRelationsAggregation.secondaryRelation, groupNode, type: .source)
            )
        }

        return triples
    }
}

