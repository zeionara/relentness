import wickedData

public struct CountableBindingTypeWithCompositionRelationsAggregation: CountableBindingTypeWithAggregation {
    public let count: Variable
    public let premise: Variable
    public let statement: Variable
    public let conclusion: Variable

    static let premiseRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/premiseCompositionRelation")
    static let statementRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/statementCompositionRelation")
    static let conclusionRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/conclusionCompositionRelation")

    public var aggregationTriples: [Triple] {
        let groupNode = makeGroupingNode()

        return [
            try! Triple(NodeType.Entity(premise.value), CountableBindingTypeWithCompositionRelationsAggregation.premiseRelation, groupNode, type: .source),
            try! Triple(NodeType.Entity(statement.value), CountableBindingTypeWithCompositionRelationsAggregation.statementRelation, groupNode, type: .source),
            try! Triple(NodeType.Entity(conclusion.value), CountableBindingTypeWithCompositionRelationsAggregation.conclusionRelation, groupNode, type: .source)
        ]
    }
}

