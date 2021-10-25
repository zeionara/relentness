import Foundation
import Logging

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

public func traceExecutionTime<Type> (
    _ logger: Logger,
    _ function: () async throws -> Type
) async throws -> (Type, Double) {
    try await measureExecutionTime(function) { output, nSeconds in
        logger.trace(
            "Execution time is \(String(format: "%.3f", nSeconds)) seconds"
        )
        return (output, nSeconds)
    }
}

