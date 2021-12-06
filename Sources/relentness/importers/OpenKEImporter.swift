import Foundation
import Logging

public typealias IndexedTriple = (head: Int, relation: Int, tail: Int)
public typealias StringifiedTriple = (head: String, relation: String, tail: String)

public class DictionaryOfArrays<Key, Item> where Key: Hashable {
    public var items: [Key: [Item]]

    public init(_ items: [Key: [Item]]) {
        self.items = items
    }

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

    public func map<Value>(_ transformValue: (Key, [Item]) -> Value) -> [Key: Value] {
        var mappedValues = [Key: Value]() 

        for (key, elements) in items {
            mappedValues[key] = transformValue(key, elements)
        }

        return mappedValues
    }

    public static func +(lhs: DictionaryOfArrays<Key, Item>, rhs: DictionaryOfArrays<Key, Item>) -> DictionaryOfArrays<Key, Item> {
        var joinedContent = [Key: [Item]]()

        for (key, items) in lhs.items {
            joinedContent[key] = items
        }

        for (key, items) in rhs.items {
            if let existingItems = joinedContent[key] {
                joinedContent[key] = existingItems + items
            } else {
                joinedContent[key] = items
            }
        }

        return DictionaryOfArrays<Key, Item>(joinedContent)
    }
}
                                                                                    
public typealias RelationUsageStats = (n: Int, total: Int, ratio: Double)
public class TriplesBatch {
    public let fromHead: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]
    public let fromRelation: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]
    public let fromTail: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]
    public let fromEntity: DictionaryOfArrays<Int, IndexedTriple> //  [Int: [IndexedTriple]]

    public let name: String

    public init(
        fromHead: DictionaryOfArrays<Int, IndexedTriple>, fromRelation: DictionaryOfArrays<Int, IndexedTriple>, fromTail: DictionaryOfArrays<Int, IndexedTriple>,
        fromEntity: DictionaryOfArrays<Int, IndexedTriple>, name: String
    ) {
           self.fromHead = fromHead
           self.fromRelation = fromRelation
           self.fromTail = fromTail
           self.fromEntity = fromEntity
           self.name = name
   }


    public init(_ path: String, name: String) {
        self.name = name

        let contents = try! String(contentsOf: URL.local(path)!, encoding: .utf8) // TODO: Add exception handling
        let contentsRows = contents.rows
        let contentsWithoutHeader = contents.rows[1..<contentsRows.count]

        let fromHead = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()
        let fromRelation = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()
        let fromTail = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()
        let fromEntity = DictionaryOfArrays<Int, IndexedTriple>() // [Int: [IndexedTriple]]()

        let decodedRows = (contentsWithoutHeader.last! == "" ? contentsWithoutHeader.dropLast() : contentsWithoutHeader).map{ row -> IndexedTriple in
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

    public func getRelationStats(nRelations: Int) -> [Int: RelationUsageStats] {
        // print("Generating batchwise relation stats")
        var nTotalTriples = 0
        var nTriples = Array(repeating: 0, count: nRelations)
        // print(fromRelation.items)
        // print(nTriples)

        for (relationId, triples) in fromRelation.items {
            let count = triples.count
            nTriples[relationId] = count
            nTotalTriples += count
        }
        print("Generation batchwise relation stats")

        var stats = [Int: RelationUsageStats]()    

        _ = nTriples.enumerated().map{ (i, count) in
            stats[i] = (n: count, total: nTotalTriples, ratio: Double(count) / Double(nTotalTriples))
        }
        // print("Generated batchwise relation stats")

        return stats
    }
}
    
public class OpenKEMapping {
    private let fromId: [String]
    public var fromName: [String: [Int]] 

    public init(_ path: String, logger: Logger? = nil) {
        // fromId = [String]()
        // fromName = [String: [Int]]()
        
        let contents = try! String(contentsOf: URL.local(path)!, encoding: .utf8) // TODO: Add exception handling
        // logger.trace("Head of contents: \(contents.prefix(100))")
        let contentsRows = contents.rows
        let contentsWithoutHeader = contents.rows[1..<contentsRows.count]
        
        // print(path)

        var fromId = [String]()
        var fromName = [String: [Int]]()
        // var index = 1
        let decodedRows = (contentsWithoutHeader.last! == "" ? contentsWithoutHeader.dropLast() : contentsWithoutHeader).map{ row -> (String, String) in
            let nameAndId = row.tabSeparatedValues

            // if nameAndId.first! == "" && nameAndId.last! == "" {
            //     logger.trace("line \(index) is empty")
            // }

            // index += 1

            return (nameAndId.first!, nameAndId.last!) 
        }.sorted{
            $0.1 < $1.1
        }

        // logger.trace("First 10 decoded rows")
        // logger.trace(String(describing: decodedRows[0..<10]))

        for (name, id) in decodedRows {
            // logger.trace("name = \(name), id = \(id)")
            fromId.append(name)
            if var ids = fromName[name] {
               // logger.trace("before as int (1)")
               ids.append(id.asInt)
               // logger.trace("after as int (1)")
            } else {
               // logger.trace("before as int (2)")
               fromName[name] = [id.asInt] 
               // logger.trace("after as int (2)")
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

    public var count: Int {
        return self.fromId.count
    }
}

enum DatasetLookupError: Error {
    case noSuchRelation(relation: String)
    case noSuchEntity(entity: String)
    case noTriples(forRelation: String)
}

public struct OpenKEImporter {
    public let entityMapping: OpenKEMapping
    public let relationshipMapping: OpenKEMapping
    public let batches: [TriplesBatch]
    public let path: String

    public init(_ path: String, batches: [String]? = nil, logger: Logger? = nil) {
        self.path = path
        logger.trace("Reading entity mappings...")
        entityMapping = OpenKEMapping("./Assets/Corpora/\(path)/entity2id.txt", logger: logger)
        logger.trace("Reading relationship mappings...")
        relationshipMapping = OpenKEMapping("./Assets/Corpora/\(path)/relation2id.txt")
        logger.trace("Reading batches \((batches ?? ["train2id", "test2id", "valid2id"]).joined(separator: ", "))...")

        var batches_ = [TriplesBatch]()
        for batch in batches ?? ["train2id", "test2id", "valid2id"] {
            batches_.append(
                TriplesBatch(
                    "./Assets/Corpora/\(path)/\(batch).txt",
                    name: batch
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

    public var relationStats: [String: [String: RelationUsageStats]] {
        var stats = [String: [String: RelationUsageStats]]()

        for batch in batches {
            // print("Processing batch")
            stats[batch.name] = {
                var batchStats = [String: RelationUsageStats]()

                // print("Before loop")
                for (relationId, batchRelationStats) in batch.getRelationStats(nRelations: self.relationshipMapping.count) {
                    // print(relationId)
                    batchStats[relationshipMapping[relationId]!] = batchRelationStats
                    // print("-")
                }

                return batchStats
            }()
            // print("Processed batch")
        }

        return stats
    }
}

