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

