import wickedData

public extension Dictionary where Key == String, Value == String {
    var asOpenKEReversedIdMapping: [String] {
        var mapping = ["\(count)"]

        for (id, name) in self {
            mapping.append("\(name)\t\(id)")
        }
        
        return mapping
    }
}

public extension Array where Element == Triple {
    var asOpenKETriples: [String] {
        var triples = ["\(count)"]

        for triple in self {
            triples.append("\(triple.head.value)\t\(triple.tail.value)\t\(triple.relationship.name)")
        }

        return triples
    }
}

