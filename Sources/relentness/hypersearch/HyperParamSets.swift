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

        if let _ = hiddenSize {
            args.append("-hs")
            args.append(hiddenSize.asStringifiedHyperparameter)
        }

        if let _ = entityNegativeRate {
            args.append("-en")
            args.append(entityNegativeRate.asStringifiedHyperparameter)
        }

        if let _ = relationNegativeRate {
            args.append("-rn")
            args.append(entityNegativeRate.asStringifiedHyperparameter)
        }

        if let _ = lambda {
            args.append("-l")
            args.append(lambda.asStringifiedHyperparameter)
        }

        if let _ = optimizer {
            args.append("-opt")
            args.append((optimizer?.rawValue).asStringifiedHyperparameter)
        }

        if let _ = task {
            args.append("-tsk")
            args.append((task?.rawValue).asStringifiedHyperparameter)
        }

        if let unwrappedBern = bern {
            if unwrappedBern { 
                args.append("-brn")
            }
        }

        if let _ = relationDimension {
            args.append("-rd")
            args.append(relationDimension.asStringifiedHyperparameter)
        }

        if let _ = entityDimension {
            args.append("-ed")
            args.append(entityDimension.asStringifiedHyperparameter)
        }

        if let _ = patience {
            args.append("-p")
            args.append(patience.asStringifiedHyperparameter)
        }

        if let _ = minDelta {
            args.append("-md")
            args.append(minDelta.asStringifiedHyperparameter)
        }

        if let _ = nWorkers {
            args.append("-nw")
            args.append(nWorkers.asStringifiedHyperparameter)
        }

        if let _ = importPath {
            args.append("-ip")
            args.append(importPath.asStringifiedHyperparameter)
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

