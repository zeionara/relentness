public extension HyperParamSet {
    var grapexArgs: [String] {
        var args = [String]()

        if let _ = nEpochs {
            args.append("-e")
            args.append(nEpochs.asStringifiedHyperparameter)
        }

        if let _ = batchSize {
            args.append("-b")
            args.append(batchSize.asStringifiedHyperparameter)
        }

        if let _ = alpha {
            args.append("-a")
            args.append(alpha.asStringifiedHyperparameter)
        }

        if let _ = margin {
            args.append("--margin")
            args.append(margin.asStringifiedHyperparameter)
        }

        if let _ = hiddenSize {
            args.append("-h")
            args.append(hiddenSize.asStringifiedHyperparameter)
        }

        if let _ = entityNegativeRate {
            args.append("--entity-neg-rate")
            args.append(entityNegativeRate.asStringifiedHyperparameter)
        }

        if let _ = relationNegativeRate {
            args.append("--relation-neg-rate")
            args.append(entityNegativeRate.asStringifiedHyperparameter)
        }

        if let _ = lambda {
            args.append("-l")
            args.append(lambda.asStringifiedHyperparameter)
        }

        if let _ = optimizer {
            args.append("--optimizer")
            args.append((optimizer?.rawValue).asStringifiedHyperparameter)
        }

        if let _ = task {
            args.append("--task")
            args.append((task?.rawValue).asStringifiedHyperparameter)
        }

        if let unwrappedBern = bern {
            if unwrappedBern { 
                args.append("--bern")
            }
        }

        if let _ = relationDimension {
            args.append("--relation-dimension")
            args.append(relationDimension.asStringifiedHyperparameter)
        }

        if let _ = entityDimension {
            args.append("--entity-dimension")
            args.append(entityDimension.asStringifiedHyperparameter)
        }

        if let _ = patience {
            args.append("-p")
            args.append(patience.asStringifiedHyperparameter)
        }

        if let _ = minDelta {
            args.append("-d")
            args.append(minDelta.asStringifiedHyperparameter)
        }

        if let _ = nWorkers {
            args.append("-n")
            args.append(nWorkers.asStringifiedHyperparameter)
        }

        if let _ = importPath {
            args.append("-i")
            args.append(importPath.asStringifiedHyperparameter)
        }

        return args
    }
}

