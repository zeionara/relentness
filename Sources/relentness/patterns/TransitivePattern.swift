import wickedData

public struct CountableBindingTypeWithTransitiveRelationAggregation: CountableBindingTypeWithAggregation {
    public let count: Variable
    public let translator: Variable

    static let translatorRelation = Relationship(name: "http://relentness.nara.zeio/relation/aggregation/translatorTransitiveRelation")

    public var aggregationTriples: [Triple] {
        let groupNode = makeGroupingNode()

        return [
            try! Triple(NodeType.Entity(translator.value), CountableBindingTypeWithTransitiveRelationAggregation.translatorRelation, groupNode, type: .source),
        ]
    }
}

