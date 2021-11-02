import Foundation

public func runSubprocessAndGetOutput(path: String, args: [String], env: [String: String], dropNewLine: Bool = true) async throws -> String {
    let task = Process()

    task.executableURL = URL(fileURLWithPath: path)
    task.environment = env
    task.arguments = args

    print("Allocate pipes...")
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
    // task.standardInput = NSFileHandle.fileHandleWithNullDevice()

    print("Run task...")
    try task.run()

    print("Reading data...")
    let outputData = try? outputPipe.fileHandleForReading.readToEnd()
    let errorData = try? inputPipe.fileHandleForReading.readToEnd()
    // let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

    // var outputData = Data()
    // var index = 0
    
    // while task.isRunning { 
    //    print("Reading chunk")
    //    let outputDataChunk = try! outputPipe.fileHandleForReading.read(upToCount: 1280)
    //    print("Read chunk")
    //    if outputData.isEmpty {
    //        print("Finished reading at \(index) call")
    //        break
    //    }
    //    print("Read \(outputData.count) bytes at \(index) call")
    //    index += 1

    // outputPipe.fileHandleForReading.readabilityHandler = { handler in
    //     let data = handler.availableData

    //     if data.isEmpty {
    //         outputPipe.fileHandleForReading.readabilityHandler = nil
    //     } else {
    //         outputData.append(data)
    //     }
    // }

    //    outputData.append(outputDataChunk!)
    // }

    // print("Lines:")
    // for await line in outputPipe.fileHandleForReading.AsyncBytes {
    //     print(line)
    // }

    print("Waiting fo task to exit...")
    task.waitUntilExit()

    print("Decode string...")
    let output = String(decoding: outputData!, as: UTF8.self)
    let _ = errorData == nil ? nil : String(decoding: errorData!, as: UTF8.self)

    // let output = String(decoding: outputPipe.fileHandleForReading.availableData, as: UTF8.self)
    // let output = String(decoding: outputData, as: UTF8.self)
    print("Output: ")
    print(output)

    print("Done")

    return dropNewLine ? String(output.dropLast()) : String(output)
}
