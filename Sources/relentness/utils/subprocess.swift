import Foundation

public func runSubprocessAndGetOutput(path: String, args: [String], env: [String: String], dropNewLine: Bool = true) async throws -> String {
    let task = Process()

    task.executableURL = URL(fileURLWithPath: path)
    task.environment = env
    task.arguments = args

    let outputPipe = Pipe()
    let inputPipe = Pipe()

    task.standardOutput = outputPipe
    task.standardInput = inputPipe

    try task.run()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

    let output = String(decoding: outputData, as: UTF8.self)

    return dropNewLine ? String(output.dropLast()) : String(output)
}
