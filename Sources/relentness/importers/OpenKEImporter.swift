import Foundation

public typealias IndexedTriple = (head: Int, relation: Int, tail: Int)
public typealias StringifiedTriple = (head: String, relation: String, tail: String)

public class DictionaryOfArrays<Key, Item> where Key: Hashable {
    public var items: [Key: [Item]]

    public init() {
        items = [Key: [Item]]()
    }
    
    // public extension Dictionary<Elements> where Value == Array<Elements> {
    func insert(_ item: Item, key: Key) {
        // print("item: \(item)")
        if var elements = items[key] {
            elements.append(item)
            items[key] = elements
        } else {
            items[key] = [item]
        }
    }

    public subscript(_ key: Key) -> [Item]? {
        get {
            return items[key]
        }
        set {
            items[key] = newValue
        }
    }
    //}
}
                                                                                    
public class TriplesBatch {
    public let fromHead: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]
    public let fromRelation: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]
    public let fromTail: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]
    public let fromEntity: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]

    public init(_ path: String) {
        let contents = try! String(contentsOf: URL.local(path)!, encoding: .utf8) // TODO: Add exception handling
        let contentsRows = contents.rows
        let contentsWithoutHeader = contents.rows[1..<contentsRows.count]

        let fromHead = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()
        let fromRelation = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()
        let fromTail = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()
        let fromEntity = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()

        let decodedRows = contentsWithoutHeader.map{ row -> IndexedTriple in
            let tripleComponents = row.tabSeparatedValues

            return (head: tripleComponents.first!.asInt, relation: tripleComponents.last!.asInt, tail: tripleComponents[1].asInt) 
        }

        for triple in decodedRows {
            fromHead.insert(triple, key: triple.head)
            // print("fromRel_ = \(fromRelation.items)")
            fromRelation.insert(triple, key: triple.relation)
            // print("fromRel = \(fromRelation.items)")
            fromTail.insert(triple, key: triple.tail)

            fromEntity.insert(triple, key: triple.head)
            fromEntity.insert(triple, key: triple.tail)
            // if var triples = fromHead[triple.head] {
            //     triples.append(triple)
            // } else {
            //     fromHead[triple.head] = [triple]
            // }
        }

        self.fromHead = fromHead
        self.fromRelation = fromRelation
        self.fromTail = fromTail
        self.fromEntity = fromEntity
    }
}
    
public class OpenKEMapping {
    private let fromId: [String]
    public var fromName: [String: [Int]] 

    public init(_ path: String) {
        // fromId = [String]()
        // fromName = [String: [Int]]()
        
        let contents = try! String(contentsOf: URL.local(path)!, encoding: .utf8) // TODO: Add exception handling
        let contentsRows = contents.rows
        let contentsWithoutHeader = contents.rows[1..<contentsRows.count]
        
        // print(path)

        var fromId = [String]()
        var fromName = [String: [Int]]()
        let decodedRows = contentsWithoutHeader.map{ row -> (String, String) in
            let nameAndId = row.tabSeparatedValues

            return (nameAndId.first!, nameAndId.last!) 
        }

        for (name, id) in decodedRows {
            fromId.append(name)
            if var ids = fromName[name] {
               ids.append(id.asInt)
            } else {
               fromName[name] = [id.asInt] 
            }
        }

        self.fromId = fromId
        self.fromName = fromName
        // print(fromName)
    }

    public subscript(_ name: String) -> [Int]? {
        get {
            return self.fromName[name]
        }
    }

    public subscript(_ id: Int) -> String? {
        get {
            return self.fromId[id]
        }
    }
}

enum DatasetLookupError: Error {
    case noSuchRelation(relation: String)
    case noSuchEntity(entity: String)
    case noTriples(forRelation: String)
}

public struct OpenKEImporter {
    private let entityMapping: OpenKEMapping
    private let relationshipMapping: OpenKEMapping
    private let batches: [TriplesBatch]

    public init(_ path: String, batches: [String]? = nil) {
        entityMapping = OpenKEMapping("./Assets/Corpora/\(path)/entity2id.txt")
        relationshipMapping = OpenKEMapping("./Assets/Corpora/\(path)/relation2id.txt")

        var batches_ = [TriplesBatch]()
        for batch in batches ?? ["train2id", "test2id", "valid2id"] {
            batches_.append(
                TriplesBatch(
                    "./Assets/Corpora/\(path)/\(batch).txt"
                ) 
            )
        }

        self.batches = batches_

        // print(relationshipMapping["antiparticleOf"])
    }

    public func searchByRelation(_ relation: String, n: Int? = nil) throws -> [StringifiedTriple] {
        //get {
        // print(relationshipMapping.fromName)
        if let relationIndices = relationshipMapping[relation] {

            var triples = [StringifiedTriple]()
            let relationIndex = relationIndices.first!
            var nFoundTriples: Int = 0

            for batch in batches {
                // print(batch.fromRelation.items)
                // print(batch.fromHead.items)
                if let foundTriples = batch.fromRelation[relationIndex] {
                    for triple in foundTriples {
                        if let nUnwrapped = n, nFoundTriples >= nUnwrapped {
                            break
                        }

                        triples.append(
                            (
                                head: entityMapping[triple.head]!,
                                relation: relationshipMapping[triple.relation]!,
                                tail: entityMapping[triple.tail]!
                            )     
                        )
                        nFoundTriples += 1
                    }
                } else {
                    throw DatasetLookupError.noTriples(forRelation: relation)
                }
            }

            if triples.count == 0 {
                throw DatasetLookupError.noTriples(forRelation: relation)
            }

            return triples
        }

        throw DatasetLookupError.noSuchRelation(relation: relation)
        // }
    }

    public func searchByRelationAndEntity(_ relation: String, entity: String? = nil, n: Int? = nil) throws -> [StringifiedTriple] {
        //get {
        // print(relationshipMapping.fromName)
        if let relationIndices = relationshipMapping[relation] {

            var triples = [StringifiedTriple]()
            let relationIndex = relationIndices.first!
            var nFoundTriples: Int = 0

            var entityIndex: Int? = nil

            if let unwrappedEntity = entity {
                if let entityIndices = entityMapping[unwrappedEntity] {
                    entityIndex = entityIndices.first!
                } else {
                    throw DatasetLookupError.noSuchEntity(entity: unwrappedEntity)
                }
            }

            for batch in batches {
                // print(batch.fromRelation.items)
                // print(batch.fromHead.items)
                if let foundTriples = batch.fromRelation[relationIndex] {
                    for triple in foundTriples {
                        if let nUnwrapped = n, nFoundTriples >= nUnwrapped {
                            break
                        }

                        if let unwrappedEntityIndex = entityIndex, unwrappedEntityIndex != triple.head && unwrappedEntityIndex != triple.tail {
                            continue
                        }

                        triples.append(
                            (
                                head: entityMapping[triple.head]!,
                                relation: relationshipMapping[triple.relation]!,
                                tail: entityMapping[triple.tail]!
                            )     
                        )
                        nFoundTriples += 1
                    }
                } else {
                    throw DatasetLookupError.noTriples(forRelation: relation)
                }
            }

            if triples.count == 0 {
                throw DatasetLookupError.noTriples(forRelation: relation)
            }

            return triples
        }

        throw DatasetLookupError.noSuchRelation(relation: relation)
        // }
    }
}

