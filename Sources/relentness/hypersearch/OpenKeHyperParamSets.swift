public extension HyperParamSet {
    var openKeArgs: [String] {
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

