import wickedData

enum QueryGenerationError: Error {
    case cannotGenerateQuery(comment: String)
    case stopIteration(comment: String)

    public static func fromGeneratedQuery<BindingType: Binding>(query: CountingQueryWithAggregation<BindingType>) throws {
        if query.text.starts(with: "ERROR: Stop iteration") {
            throw Self.stopIteration(comment: query.text)
        }

        if query.text.starts(with: "ERROR: ") {
            throw Self.cannotGenerateQuery(comment: query.text)
        }
    }
}

