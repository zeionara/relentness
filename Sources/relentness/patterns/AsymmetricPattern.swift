import wickedData

public struct CountableBindingTypeWithAntisymmetricRelationsAggregation: CountableBindingTypeWithAggregation {
    public let count: Variable
    public let forward: Variable
    public let backward: Variable?

    static let forwardRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/forwardAntisymmetricRelation")
    static let backwardRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/backwardAntisymmetricRelation")

    public var aggregationTriples: [Triple] {
        let groupNode = makeGroupingNode()

        var triples = [
            try! Triple(NodeType.Entity(forward.value), CountableBindingTypeWithAntisymmetricRelationsAggregation.forwardRelation, groupNode, type: .source)
        ]

        if let unwrappedBackwardRelation = backward {
            triples.append(
                try! Triple(NodeType.Entity(unwrappedBackwardRelation.value), CountableBindingTypeWithAntisymmetricRelationsAggregation.backwardRelation, groupNode, type: .source)
            )
        }

        return triples
    }
}

