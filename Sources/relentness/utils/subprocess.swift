import Foundation

public func runSubprocessAndGetOutput(path: String, args: [String], env: [String: String], dropNewLine: Bool = true) async throws -> String {
    let task = Process()

    task.executableURL = URL(fileURLWithPath: path)
    task.environment = env
    task.arguments = args

    // print("Allocate pipes...")
    let outputPipe = Pipe()
    let inputPipe = Pipe()

    defer {
        try? outputPipe.fileHandleForReading.close()
        try? outputPipe.fileHandleForWriting.close()

        try? inputPipe.fileHandleForReading.close()
        try? inputPipe.fileHandleForWriting.close()
    }

    task.standardOutput = outputPipe
    task.standardInput = inputPipe

    // print("Run task...")
    try task.run()

    // print("Read data...")
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()


    // print("Decode string...")
    let output = String(decoding: outputData, as: UTF8.self)

    // print("Done")

    return dropNewLine ? String(output.dropLast()) : String(output)
}
