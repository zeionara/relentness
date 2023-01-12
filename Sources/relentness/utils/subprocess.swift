import Foundation

public func runSubprocessAndGetOutput(path: String, args: [String], env: [String: String], dropNewLine: Bool = true, terminationDelay: Double? = nil, retryOnError: Bool = false) throws -> String? {
    let task = Process()

    task.executableURL = URL(fileURLWithPath: path)
    task.environment = env
    task.arguments = args

    let outputPipe = Pipe()
    let errorPipe = Pipe()

    task.standardOutput = outputPipe
    task.standardError = errorPipe

    try task.run()

    if let unwrappedErrorData = try? errorPipe.fileHandleForReading.readToEnd() {
        print(
            String(decoding: unwrappedErrorData, as: UTF8.self)
        )
    }
    let outputData = try? outputPipe.fileHandleForReading.readToEnd()

    task.waitUntilExit()

    if let unwrappedOutputData = outputData {
        let output = String(decoding: unwrappedOutputData, as: UTF8.self)
        return dropNewLine ? String(output.dropLast()) : String(output)
    }

    return nil
}

public func runScriptAndGetOutput(_ fileName: String) throws -> String? {
    try runSubprocessAndGetOutput(
        path: "/bin/bash",
        args: ["Assets/Scripts/Shell/\(fileName).sh"],
        env: [:]
    )
}

// public func runSubprocessAndGetOutput(path: URL, executable: URL, args: [String], env: [String: String], dropNewLine: Bool = true, terminationDelay: Double? = nil, retryOnError: Bool = false) async throws -> String {
public func runSubprocessAndGetOutput(path: URL, executable: URL, args: [String], env: [String: String], dropNewLine: Bool = true, terminationDelay: Double? = nil, retryOnError: Bool = false) async throws -> MetricTree {
    while true { // Repeat process execution until success (testing process can be killed with kill -9 $(ps -aux | grep "python -m relentness" | grep -v "grep" | cut -d " " -f7)
        let task = Process()

        // task.executableURL = URL(fileURLWithPath: path)
        task.executableURL = executable
        task.currentDirectoryURL = path
        // print(env)
        // print(ProcessInfo.processInfo.environment)
        // task.environment = env
        task.environment = ProcessInfo.processInfo.environment.merging(env) { (_, new) in new }
        task.arguments = args

        let outputPipe = Pipe()
        let inputPipe = Pipe()

        // var terminatingTask: Task<Void, Error>? = nil
        
        if let unwrappedTerminationDelay = terminationDelay { 
            // terminatingTask =
            Task {
                usleep(UInt32(unwrappedTerminationDelay * 1_000_000))
                if task.isRunning {
                    // print("Terminating task (pid = \(task.processIdentifier)). Task is running: \(task.isRunning)...")
                    // task.terminate()
                    // print("Terminated locally task with pid = \(task.processIdentifier)")
                    // sleep(30)
                    // let _ = try? await runSubprocessAndGetOutput(path: "/usr/bin/kill", args: ["-9", String(describing: task.processIdentifier), "||", "true"], env: [String: String](), retryOnError: false)
                    let _ = try? await runSubprocessAndGetOutput(path: "/bin/bash", args: ["-c", "kill -9 \(task.processIdentifier) 2>/dev/null || echo 'no such process'"], env: [String: String](), retryOnError: false)
                    // print("Terminated task with pid = \(task.processIdentifier)")
                }
            }
        }

        defer {
            try? outputPipe.fileHandleForReading.close()
            try? outputPipe.fileHandleForWriting.close()

            try? inputPipe.fileHandleForReading.close()
            try? inputPipe.fileHandleForWriting.close()

            // terminatingTask?.cancel()
        }

        task.standardOutput = outputPipe
        // task.standardError = inputPipe
        task.standardError = inputPipe


        do {
            try task.run()

            if let unwrappedErrorData = try? inputPipe.fileHandleForReading.readToEnd() {
                print(
                    String(decoding: unwrappedErrorData, as: UTF8.self)
                )
            }
            let outputData = try? outputPipe.fileHandleForReading.readToEnd()

            task.waitUntilExit()

            // print("output: ")
            if let unwrappedOutputData = outputData {
                let output = String(decoding: unwrappedOutputData, as: UTF8.self)
                // print(unwrappedOutputData)
                // print(unwrappedOutputData.base64EncodedString())
                // unwrappedOutputData.forEach{item in print(item)}
                // print(unwrappedOutputData[0], unwrappedOutputData[1])
                // print(type(of: unwrappedOutputData))
                // print(output.unicodeScalars.map{character in character.value})
                // print(try output.bytes)
                // print(try MetricTree(from: output))
                return try MetricTree(from: output)
                // return dropNewLine ? String(output.dropLast()) : String(output)
            }
        } catch {
            if retryOnError {
                print("Error running subprocess, retrying...")
            } else {
                print("Subprocess thrown an exception: \(String(describing: error)), exiting...")
                // return String(describing: error)
            }
        }
        // let _ = errorData == nil ? nil : String(decoding: errorData!, as: UTF8.self)
    }
}
