public extension Array {
    func grouped<Key>(_ getKey: (Element) -> Key) -> [Key: [Element]] {
        let items = DictionaryOfArrays<Key, Element>()

        for element in self {
            items.insert(element, key: getKey(element))
        }

        return items.items
    }
}

let PREFIX = "ren"

public extension TriplesBatch {
    static func +(lhs: TriplesBatch, rhs: TriplesBatch) -> TriplesBatch {
        TriplesBatch(
            fromHead: lhs.fromHead + rhs.fromHead,
            fromRelation: lhs.fromRelation + rhs.fromRelation,
            fromTail: lhs.fromTail + rhs.fromTail,
            fromEntity: lhs.fromEntity + rhs.fromEntity,
            name: "\(lhs.name) & \(rhs.name)"
        )
    }
}

public extension OpenKEImporter {
    var asTtl: String {
        var rows = ["@prefix \(PREFIX): <https://relentness.nara.zeio/\(path)/> .", ""]

        let joinedBatch = batches.reduce(
            TriplesBatch(
                fromHead: DictionaryOfArrays<Int, IndexedTriple>([Int: [IndexedTriple]]()),
                fromRelation: DictionaryOfArrays<Int, IndexedTriple>([Int: [IndexedTriple]]()),
                fromTail: DictionaryOfArrays<Int, IndexedTriple>([Int: [IndexedTriple]]()),
                fromEntity: DictionaryOfArrays<Int, IndexedTriple>([Int: [IndexedTriple]]()),
                name: ""
            ),
            +
        )
        
        let _ = joinedBatch.fromHead.map{ (key, items) in
            let headTerm = "\(PREFIX):\(entityMapping[key]!.lastPathComponent)"
            let relationsAndTails = items.grouped{ item in
               item.relation
            }.map{ (relation, triples) in
                let relationTerm = "\(PREFIX):\(relationshipMapping[relation]!.lastPathComponent)"
                let joinedTails = triples.map{ triple in
                    "\(PREFIX):\(entityMapping[triple.tail]!.lastPathComponent)"
                }.joined(separator: ", ")
                return "\(relationTerm) \(joinedTails)"
            }.joined(separator: "; ")
            rows.append("\(headTerm) \(relationsAndTails) .")
        }

        return rows.joined(separator: "\n")
    }

    func toTtl(_ path: String? = nil) {
        write(
            path ?? "./Assets/Corpora/\(self.path)/model.ttl",
            asTtl
        )
    }
}

