import Foundation
import Yams

public struct HyperParamSet: CustomStringConvertible {
    public let nEpochs: Int?
    public let nBatches: Int?

    public static var header: String {
        "n-epochs\tn-batches"
    }

    public var description: String {
        "\(nEpochs == nil ? "-" : String(describing: nEpochs!))\t\(nBatches == nil ? "-" : String(describing: nBatches!))"
    }
}

public extension HyperParamSet {
    public var openKeArgs: [String] {
        var args = [String]()

        if let nEpochs_ = nEpochs {
            args.append("-e")
            args.append(String(describing: nEpochs_))
        }

        if let nBatches_ = nBatches {
            args.append("-b")
            args.append(String(describing: nBatches_))
        }

        return args
    }
}


public extension Optional where Wrapped: Collection {
    var values: [Wrapped.Element?] {
        if let unwrappedArray = self {
            return unwrappedArray as! [Wrapped.Element?]
        }
        let nilItem: Wrapped.Element? = nil
        return [nilItem]
    }
}

public struct HyperParamStorage: Codable {
    public let nEpochs: [Int]?
    public let nBatches: [Int]?

    public var sets: [HyperParamSet] {
        var result = [HyperParamSet]()

        nEpochs.values.map { nEpochs_ in
            for nBatches_ in nBatches.values {
                result.append(
                    HyperParamSet(
                        nEpochs: nEpochs_,
                        nBatches: nBatches_
                    )
                )
            }
            // nBatches.values.map { nBatches_ in
            //     HyperParamSet(
            //         nEpochs: nEpochs_,
            //         nBatches: nBatches_
            //     )
            // }
        }

        return result
    }
}

public struct HyperParamSets {
    let path: String?
    let storage: HyperParamStorage

    public init(_ path: String) { // TODO: Implement exception handling
        let decoder = YAMLDecoder()
        storage = try! decoder.decode(
            HyperParamStorage.self, 
            from: try! String(contentsOf: URL.local(path)!, encoding: .utf8)
        )
        self.path = path
        // print(storage.sets)
    }
}

