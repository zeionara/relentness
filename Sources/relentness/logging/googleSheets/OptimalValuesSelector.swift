import wickedData

public extension Collection where Element == ModelTestingResult {
    func getOptimalValueLocations(offset: CellLocation = CellLocation(row: 0, column: 0)) -> [CellLocation] {
        var optimalValues = (
            meanRank: Double.infinity, meanReciprocalRank: -Double.infinity, hitsAtOne: -Double.infinity, hitsAtThree: -Double.infinity, hitsAtTen: -Double.infinity,
            time: Double.infinity, totalTime: Double.infinity, executionTime: Double.infinity
        )
        var optimalValueIndices = (
            meanRank: [Int](), meanReciprocalRank: [Int](), hitsAtOne: [Int](), hitsAtThree: [Int](), hitsAtTen: [Int](),
            time: [Int](), totalTime: [Int](), executionTime: [Int]() 
        )

        for (i, testingResult) in self.enumerated() {
            if testingResult.meanMetrics.meanRank < optimalValues.meanRank {
                optimalValues.meanRank = testingResult.meanMetrics.meanRank
                optimalValueIndices.meanRank = [i]
            } else if testingResult.meanMetrics.meanRank == optimalValues.meanRank {
                optimalValueIndices.meanRank.append(i)
            }

            if testingResult.meanMetrics.meanReciprocalRank > optimalValues.meanReciprocalRank {
                optimalValues.meanReciprocalRank = testingResult.meanMetrics.meanReciprocalRank
                optimalValueIndices.meanReciprocalRank = [i]
            } else if testingResult.meanMetrics.meanReciprocalRank == optimalValues.meanReciprocalRank {
                optimalValueIndices.meanReciprocalRank.append(i)
            }

            if testingResult.meanMetrics.hitsAtOne > optimalValues.hitsAtOne {
                optimalValues.hitsAtOne = testingResult.meanMetrics.hitsAtOne
                optimalValueIndices.hitsAtOne = [i]
            } else if testingResult.meanMetrics.hitsAtOne == optimalValues.hitsAtOne {
                optimalValueIndices.hitsAtOne.append(i)
            }

            if testingResult.meanMetrics.hitsAtThree > optimalValues.hitsAtThree {
                optimalValues.hitsAtThree = testingResult.meanMetrics.hitsAtThree
                optimalValueIndices.hitsAtThree = [i]
            } else if testingResult.meanMetrics.hitsAtThree == optimalValues.hitsAtThree {
                optimalValueIndices.hitsAtThree.append(i)
            }

            if testingResult.meanMetrics.hitsAtTen > optimalValues.hitsAtTen {
                optimalValues.hitsAtTen = testingResult.meanMetrics.hitsAtTen
                optimalValueIndices.hitsAtTen = [i]
            } else if testingResult.meanMetrics.hitsAtTen == optimalValues.hitsAtTen {
                optimalValueIndices.hitsAtTen.append(i)
            }

            if let unwrappedTime = testingResult.meanMetrics.time {
                if unwrappedTime < optimalValues.time {
                    optimalValues.time = unwrappedTime
                    optimalValueIndices.time = [i]
                } else if unwrappedTime == optimalValues.time {
                    optimalValueIndices.time.append(i)
                }
            }

            if let unwrappedTime = testingResult.meanMetrics.totalTime ?? testingResult.meanMetrics.time {
                if unwrappedTime < optimalValues.totalTime {
                    optimalValues.totalTime = unwrappedTime
                    optimalValueIndices.totalTime = [i]
                } else if unwrappedTime == optimalValues.totalTime {
                    optimalValueIndices.totalTime.append(i)
                }
            }

            if testingResult.executionTime < optimalValues.executionTime {
                optimalValues.executionTime = testingResult.executionTime
                optimalValueIndices.executionTime = [i]
            } else if testingResult.executionTime == optimalValues.executionTime {
                optimalValueIndices.executionTime.append(i)
            }
        }

        let meanRankCellLocations = optimalValueIndices.meanRank.count < count ? optimalValueIndices.meanRank.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.meanRank.rawValue)
        } : [CellLocation]()
        
        let meanReciprocalRankCellLocations = optimalValueIndices.meanReciprocalRank.count < count ? optimalValueIndices.meanReciprocalRank.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.meanReciprocalRank.rawValue)
        } : [CellLocation]()
        
        let hitsAtOneCellLocations = optimalValueIndices.hitsAtOne.count < count ? optimalValueIndices.hitsAtOne.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.hitsAtOne.rawValue)
        } : [CellLocation]()
        
        let hitsAtThreeCellLocations = optimalValueIndices.hitsAtThree.count < count ? optimalValueIndices.hitsAtThree.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.hitsAtThree.rawValue)
        } : [CellLocation]()
        
        let hitsAtTenCellLocations = optimalValueIndices.hitsAtTen.count < count ? optimalValueIndices.hitsAtTen.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.hitsAtTen.rawValue)
        } : [CellLocation]()

        let timeCellLocations = optimalValueIndices.time.count < count ? optimalValueIndices.time.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.time.rawValue)
        } : [CellLocation]()

        let totalTimeCellLocations = optimalValueIndices.totalTime.count < count ? optimalValueIndices.totalTime.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.totalTime.rawValue)
        } : [CellLocation]()

        let executionTimeCellLocations = optimalValueIndices.executionTime.count < count ? optimalValueIndices.executionTime.map{
            CellLocation(row: $0 + offset.row, column: offset.column + MeagerMetricSeries.Metric.executionTime.rawValue)
        } : [CellLocation]()

        return meanRankCellLocations + meanReciprocalRankCellLocations + hitsAtOneCellLocations + hitsAtThreeCellLocations + hitsAtTenCellLocations + timeCellLocations + totalTimeCellLocations +
            executionTimeCellLocations
    }
}

typealias DatasetTestingResult = [PatternStats<CountableBindingTypeWithOneRelationAggregation>.Metric: Double]

public enum OptimizationPath {
    case up, down
}

extension Collection where Element == DatasetTestingResult {
    func getOptimalValueLocations(offset: CellLocation = CellLocation(row: 0, column: 0)) -> [CellLocation] {
        var optimalValues: [PatternStats<CountableBindingTypeWithOneRelationAggregation>.Metric: Double] = [ // TODO: Rename to initialValues
            .positiveRatio: -Double.infinity,
            .negativeRatio: -Double.infinity,
            .positiveNormalizedRatio: -Double.infinity,
            .negativeNormalizedRatio: -Double.infinity,
            .relativeRatio: -Double.infinity,
            .nPositiveOccurrences: -Double.infinity,
            .nNegativeOccurrences: -Double.infinity,
            .nTriples: -Double.infinity,
            .executionTime: Double.infinity
        ]
        var optimalValueIndices: [PatternStats<CountableBindingTypeWithOneRelationAggregation>.Metric: [Int]] = [
            .positiveRatio: [Int](),
            .negativeRatio: [Int](),
            .positiveNormalizedRatio: [Int](),
            .negativeNormalizedRatio: [Int](),
            .relativeRatio: [Int](),
            .nPositiveOccurrences: [Int](),
            .nNegativeOccurrences: [Int](),
            .nTriples: [Int](),
            .executionTime: [Int]()
        ]
        let optimizationPaths = Dictionary(
            uniqueKeysWithValues: optimalValues.map { metric, value in
                (metric, value == Double.infinity ? OptimizationPath.down : OptimizationPath.up)
            }
        )
        // [PatternStats<CountableBindingTypeWithOneRelationAggregation>.Metric: OptimizationPath] = [
        //     .positiveRatio: .up,
        //     .negativeRatio: .up,
        //     .positiveNormalizedRatio: .up,
        //     .negativeNormalizedRatio: .up,
        //     .relativeRatio: .up,
        //     .nPositiveOccurrences: .up,
        //     .nNegativeOccurrences: .up,
        //     .nTriples: .up,
        //     .executionTime: .down
        // ]

        for (i, testingResult) in self.enumerated() {
            for metric in PatternStats<CountableBindingTypeWithOneRelationAggregation>.Metric.allCases {
                if ((testingResult[metric]! > optimalValues[metric]! && optimizationPaths[metric]! == .up) || (testingResult[metric]! < optimalValues[metric]! && optimizationPaths[metric]! == .down)) {
                    optimalValues[metric] = testingResult[metric]!
                    optimalValueIndices[metric] = [i]
                } else if testingResult[metric] == optimalValues[metric]! {
                    optimalValueIndices[metric]!.append(i)
                }
            }
        }

        // print(optimalValueIndices)

        var optimalValueCellLocations = [CellLocation]()


        for (i, metric) in PatternStats<CountableBindingTypeWithOneRelationAggregation>.Metric.allCases.enumerated() {
            if optimalValueIndices[metric]!.count < count {
                optimalValueCellLocations.append(
                    contentsOf: optimalValueIndices[metric]!.map{
                        CellLocation(row: offset.row + $0, column: offset.column + i)
                    }
                )
            }
        }

        return optimalValueCellLocations
    }
}
