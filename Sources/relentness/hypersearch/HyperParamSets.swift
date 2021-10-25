import Foundation
import Yams

public extension Optional where Wrapped == Int {
    var asStringifiedHyperparameter: String {
        if let unwrapped = self {
            return String(describing: unwrapped)
        }
        return "-"
    }
}


public extension Optional where Wrapped == Double {
    var asStringifiedHyperparameter: String {
        if let unwrapped = self {
            return String(format: "%.5f", unwrapped)
        }
        return "-"
    }
}

public struct HyperParamSet: CustomStringConvertible {
    public let nEpochs: Int?
    public let nBatches: Int?
    public let alpha: Double?
    public let margin: Double?
    public let dimension: Int?
    public let entityNegativeRate: Int?

    public static var header: String {
        "n-epochs\tn-batches\talpha\tmargin\tdimension\tentity-neg-rate"
    }

    public var description: String {
        "\(nEpochs.asStringifiedHyperparameter)\t\(nBatches.asStringifiedHyperparameter)\t\(alpha.asStringifiedHyperparameter)\t\(margin.asStringifiedHyperparameter)\t" +
        "\(dimension.asStringifiedHyperparameter)\t\(entityNegativeRate.asStringifiedHyperparameter)"
    }
}

public extension HyperParamSet {
    var openKeArgs: [String] {
        var args = [String]()

        if let _ = nEpochs {
            args.append("-e")
            args.append(nEpochs.asStringifiedHyperparameter)
        }

        if let _ = nBatches {
            args.append("-b")
            args.append(nBatches.asStringifiedHyperparameter)
        }

        if let _ = alpha {
            args.append("-a")
            args.append(alpha.asStringifiedHyperparameter)
        }

        if let _ = margin {
            args.append("-ma")
            args.append(margin.asStringifiedHyperparameter)
        }

        if let _ = dimension {
            args.append("-d")
            args.append(dimension.asStringifiedHyperparameter)
        }

        if let _ = entityNegativeRate {
            args.append("-n")
            args.append(entityNegativeRate.asStringifiedHyperparameter)
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
    public let alpha: [Double]?
    public let margin: [Double]?
    public let dimension: [Int]?
    public let entityNegativeRate: [Int]?

    public var sets: [HyperParamSet] {
        var result = [HyperParamSet]()

        _ = nEpochs.values.map { nEpochs_ in
            for nBatches_ in nBatches.values {
                for alpha_ in alpha.values {
                    for margin_ in margin.values {
                        for dimension_ in dimension.values {
                            for entityNegativeRate_ in entityNegativeRate.values {
                                result.append(
                                    HyperParamSet(
                                        nEpochs: nEpochs_,
                                        nBatches: nBatches_,
                                        alpha: alpha_,
                                        margin: margin_,
                                        dimension: dimension_,
                                        entityNegativeRate: entityNegativeRate_
                                    )
                                )
                            }
                        }
                    }
                }
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

    public init(_ corpus: String, _ model: String, _ path: String) { // TODO: Implement exception handling
        let decoder = YAMLDecoder()
        storage = try! decoder.decode(
            HyperParamStorage.self, 
            from: try! String(contentsOf: URL.local("./Assets/Hypersearch/\(corpus)/\(model)/\(path).yml")!, encoding: .utf8)
        )
        self.path = path
        // print(storage.sets)
    }
}

