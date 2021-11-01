import Logging
import Foundation

public extension URL{
    static func local(_ path: String) -> URL? {
        return Self(
            fileURLWithPath: FileManager.default.currentDirectoryPath
        ).appendingPathComponent(path)
    }
}


enum FileError: Error {
    case invalidPath(message: String)
}


public func getParentFolderPath(_ path: String) throws -> String  {
    let splits = String(path.reversed()).split(separator: "/", maxSplits: 1)
    if let parentFolderReversedPath = splits.last, splits.count == 2 {
        return String(parentFolderReversedPath.reversed())
    }
    throw FileError.invalidPath(message: "Cannot get parent folder from path \(path)")
}


public func makeSureParentFoldersExist(_ path: String) throws {
    let parentFolderPath = try getParentFolderPath(path)
    try FileManager.default.createDirectory(atPath: parentFolderPath, withIntermediateDirectories: true, attributes: nil)
}

public func makeSureFileExists(_ url: URL, recreate: Bool = false) {
    do {
        // print("Check file exists, recreate = \(recreate)")
        if (!FileManager.default.fileExists(atPath: url.path) || recreate) {
            try Data("".utf8).write(to: url)
        }
    } catch {
        print("Cannot create file \(url) because of exception \(error)") 
    }
}


public func makeSureFileExists(_ path: String, recreate: Bool = false) {
    do{
        try makeSureParentFoldersExist(path)
    } catch {
        print("Cannot create parent folders for file \(path) because of exception \(error)")
    }
    
    if let fileURL = URL.local(path) { 
        makeSureFileExists(fileURL, recreate: recreate)
    } else {
        print("Cannot make sure that file \(path) exists because given path is not correct")
    }
}

public func createDirectory(_ path: String, logger: Logger? = nil) {
    do {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    } catch {
        if let loggerUnwrapped = logger {
            loggerUnwrapped.error("Cannot create the required directory \(path)")
        } else {
            print("Cannot create the required directory \(path)")
        }
    }
}

public func writeLines(_ path: String, _ lines: [String], logger: Logger? = nil) {
    do {                                                                                                                                                                                                                 
        if let url = URL.local(path) {                                                                                                                                                              
            try lines.joined(separator: "\n").write(to: url, atomically: false, encoding: .utf8)                                                                                                                            
        } else {                                                                                                                                                                                    
            let message = "Path \(path) cannot be considered a valid url" 
            if let loggerUnwrapped = logger {
                loggerUnwrapped.error("\(message)")
            } else {
                print(message)
            }
        }                                                                                                                                                                                           
    } catch {                                                                                                                                                                                       
        let message = "Cannot save data bundle as tsv because of exception: \(error.localizedDescription)" 
        if let loggerUnwrapped = logger {
            loggerUnwrapped.error("\(message)")
        } else {
            print(message)
        }
    }
}

public func write(_ path: String, _ content: String, logger: Logger? = nil) {
    do {                                                                                                                                                                                                                 
        // print("Writing to \(path)")
        makeSureFileExists(path, recreate: true)
        if let url = URL.local(path) {                                                                                                                                                              
            try content.write(to: url, atomically: false, encoding: .utf8)                                                                                                                            
        } else {                                                                                                                                                                                    
            let message = "Path \(path) cannot be considered a valid url" 
            if let loggerUnwrapped = logger {
                loggerUnwrapped.error("\(message)")
            } else {
                print(message)
            }
        }                                                                                                                                                                                           
    } catch {                                                                                                                                                                                       
        let message = "Cannot save data bundle as tsv because of exception: \(error.localizedDescription)" 
        if let loggerUnwrapped = logger {
            loggerUnwrapped.error("\(message)")
        } else {
            print(message)
        }
    }
}

public func getNestedFolderNames(_ path: String) -> [String] { // TODO: Implement exception handling
    let fileManager = FileManager.default
    let contents = try! fileManager.contentsOfDirectory(
        at: URL.local(path)!,
        includingPropertiesForKeys: nil
    )

    var isDir: ObjCBool = false
    return contents.filter { file in
        fileManager.fileExists(atPath: file.path, isDirectory: &isDir) && isDir.boolValue
    }.map{ file in
        file.lastPathComponent
    }.sorted()
    // print(contents.first!.lastPathComponent)
    // print(result.count)
    // return result
}

