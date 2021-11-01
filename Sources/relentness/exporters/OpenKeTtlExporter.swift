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

public extension OpenKEImporter {
    var asTtl: String {
        var rows = ["@prefix \(PREFIX): <https://relentness.nara.zeio/\(path)/> .", ""]

        let _ = batches.map{ batch in
            batch.fromHead.map{ (key, items) in
                let headTerm = "\(PREFIX):\(entityMapping[key]!.lastPathComponent)"
                // items.grouped{ item in
                //    item.relation
                // }.map{ (relation, triples) in
                //     print("\(PREFIX):\(relationshipMapping[relation]!.lastPathComponent)")
                //     let joinedTails = triples.map{ triple in
                //         "\(PREFIX):\(entityMapping[triple.tail]!.lastPathComponent)"
                //     }.joined(separator: ", ")
                //     print("\(joinedTails) ;")
                // }
                // print(".")
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
        } 

        // print(batchesWithTwoLevelGrouping)
        // print(relationshipMapping)
        // print("@prefix \(PREFIX): <https://relentness.nara.zeio/\(path)/> .")

        return rows.joined(separator: "\n") // "foo-bar"
    }

    func toTtl(_ path: String? = nil) {
        write(
            path ?? "./Assets/Corpora/\(self.path)/model.ttl",
            asTtl
        )
    }
}

