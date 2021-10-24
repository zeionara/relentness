import Foundation

public func measureExecutionTime<IntermediateResultType, FinalResultType>(
    _ function: () async throws -> IntermediateResultType,
    handleExecutionTimeMeasurement: (IntermediateResultType, Double) -> FinalResultType
) async throws -> FinalResultType {
    let start = DispatchTime.now()
    let result = try await function()
    let end = DispatchTime.now()
    let nSeconds = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000

    return handleExecutionTimeMeasurement(result, nSeconds)
}

