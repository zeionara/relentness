import Foundation
import Yams
import Logging

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

public extension Optional where Wrapped == String {
    var asStringifiedHyperparameter: String {
        if let unwrapped = self {
            return unwrapped
        }
        return "-"
    }
}

public extension Optional where Wrapped == Bool {
    var asStringifiedHyperparameter: String {
        if let unwrapped = self {
            return unwrapped ? "true" : "false"
        }
        return "-"
    }
}

public enum Optimizer: String, CaseIterable, Sendable, Codable {
    case adagrad
    case adadelta
    case adam
    case sgd
}

public enum EvaluationTask: String, CaseIterable, Sendable, Codable {
    case linkPrediction = "link-prediction"
    case tripleClassification = "triple-classification"

    // public var kebabCased: String {
    //     switch self {
    //         case .linkPrediction:
    //             return "link-prediction"
    //         case .tripleClassification:
    //             return "triple-classification"
    //     }
    // }
}

public struct HyperParamSet: CustomStringConvertible, Sendable {
    public let nEpochs: Int?
    public let nBatches: Int?
    public let alpha: Double?
    public let margin: Double?
    public let hiddenSize: Int?
    public let entityNegativeRate: Int?

    public let relationNegativeRate: Int?
    public let lambda: Double?
    public let optimizer: Optimizer?
    public let task: EvaluationTask?
    public let bern: Bool?
    public let relationDimension: Double?
    public let entityDimension: Double?
    public let patience: Int?
    public let minDelta: Double?
    public let nWorkers: Int?
    public let importPath: String?

    public static var header: String {
        "n-epochs\tn-batches\talpha\tmargin\tdimension\tentity-neg-rate\trelation-neg-rate\tlambda\toptimizer\ttask\tbern\trelation-dim\tentity-dim\tpatience\tmin-delta\tn-workers\timport-path"
    }

    public var description: String {
        "\(nEpochs.asStringifiedHyperparameter)\t\(nBatches.asStringifiedHyperparameter)\t\(alpha.asStringifiedHyperparameter)\t\(margin.asStringifiedHyperparameter)\t" +
        "\(hiddenSize.asStringifiedHyperparameter)\t\(entityNegativeRate.asStringifiedHyperparameter)\t" +
        "\(relationNegativeRate.asStringifiedHyperparameter)\t\(lambda.asStringifiedHyperparameter)\t\((optimizer?.rawValue).asStringifiedHyperparameter)\t" + 
        "\((task?.rawValue).asStringifiedHyperparameter)\t\(bern.asStringifiedHyperparameter)\t" +
        "\(relationDimension.asStringifiedHyperparameter)\t\(entityDimension.asStringifiedHyperparameter)\t\(patience.asStringifiedHyperparameter)\t\(minDelta.asStringifiedHyperparameter)\t" +
        "\(nWorkers.asStringifiedHyperparameter)\t\(importPath.asStringifiedHyperparameter)"
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
    public let hiddenSize: [Int]?
    public let entityNegativeRate: [Int]?

    public let relationNegativeRate: [Int]?
    public let lambda: [Double]?
    public let optimizer: [Optimizer]?
    public let task: [EvaluationTask]?
    public let bern: [Bool]?
    public let relationDimension: [Double]?
    public let entityDimension: [Double]?
    public let patience: [Int]?
    public let minDelta: [Double]?
    public let nWorkers: [Int]?
    public let importPath: [String]?

    public var sets: [HyperParamSet] {
        var result = [HyperParamSet]()

        _ = nEpochs.values.map { nEpochs_ in
            for nBatches_ in nBatches.values {
                for alpha_ in alpha.values {
                    for margin_ in margin.values {
                        for hiddenSize_ in hiddenSize.values {
                            for entityNegativeRate_ in entityNegativeRate.values {
                                for relationNegativeRate_ in relationNegativeRate.values {
                                    for lambda_ in lambda.values {
                                        for optimizer_ in optimizer.values {
                                            for task_ in task.values {
                                                for bern_ in bern.values {
                                                    for relationDimension_ in relationDimension.values {
                                                        for entityDimension_ in entityDimension.values {
                                                            for patience_ in patience.values {
                                                                for minDelta_ in minDelta.values {
                                                                    for nWorkers_ in nWorkers.values {
                                                                        for importPath_ in importPath.values {
                                                                            result.append(
                                                                                HyperParamSet(
                                                                                    nEpochs: nEpochs_,
                                                                                    nBatches: nBatches_,
                                                                                    alpha: alpha_,
                                                                                    margin: margin_,
                                                                                    hiddenSize: hiddenSize_,
                                                                                    entityNegativeRate: entityNegativeRate_,
                                                                                    relationNegativeRate: relationNegativeRate_,
                                                                                    lambda: lambda_,
                                                                                    optimizer: optimizer_,
                                                                                    task: task_,
                                                                                    bern: bern_,
                                                                                    relationDimension: relationDimension_,
                                                                                    entityDimension: entityDimension_,
                                                                                    patience: patience_,
                                                                                    minDelta: minDelta_,
                                                                                    nWorkers: nWorkers_,
                                                                                    importPath: importPath_ 
                                                                                )
                                                                            )
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
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

public extension Optional where Wrapped == Logger {
    func error(_ message: String) {
        if let logger = self {
            logger.error(Logger.Message(stringLiteral: message))
        } else {
            print(message)
        }
    }
}

enum HyperParamSetsException: Error {
    case invalidFile(path: String)
}

public struct HyperParamSets {
    let path: String?
    let storage: HyperParamStorage

    public init(_ corpus: String, _ model: String, _ path: String, logger: Logger? = nil) throws { // TODO: Implement exception handling
        let decoder = YAMLDecoder()
        let absolute_path = URL.local("./Assets/Hypersearch/\(corpus)/\(model)/\(path).yml")!
        do {
            storage = try decoder.decode(
                HyperParamStorage.self, 
                from: try String(contentsOf: absolute_path, encoding: .utf8)
            )
        } catch {
            logger.error("Cannot read hyperparameter sets from file '\(absolute_path)'")    
            throw HyperParamSetsException.invalidFile(path: path)
            // print(storage.sets)
        }
        self.path = path
    }
}

