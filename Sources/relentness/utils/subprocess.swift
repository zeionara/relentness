import Foundation

public func runSubprocessAndGetOutput(path: String, args: [String], env: [String: String], dropNewLine: Bool = true) async throws -> String {
    let task = Process()

    task.executableURL = URL(fileURLWithPath: path)
    task.environment = env
    task.arguments = args

    let outputPipe = Pipe()
    let inputPipe = Pipe()

    defer {
        try? outputPipe.fileHandleForReading.close()
        try? outputPipe.fileHandleForWriting.close()

        try? inputPipe.fileHandleForReading.close()
        try? inputPipe.fileHandleForWriting.close()
    }

    task.standardOutput = outputPipe
    task.standardError = inputPipe

    try task.run()

    let outputData = try? outputPipe.fileHandleForReading.readToEnd()
    let errorData = try? inputPipe.fileHandleForReading.readToEnd()

    task.waitUntilExit()

    let output = String(decoding: outputData!, as: UTF8.self)
    let _ = errorData == nil ? nil : String(decoding: errorData!, as: UTF8.self)

    return dropNewLine ? String(output.dropLast()) : String(output)
}
