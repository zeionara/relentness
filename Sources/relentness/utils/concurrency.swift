import Foundation

let DEFAULT_N_WORKERS = 2

extension Collection where Element: Sendable {
    //
    // Taken from https://gist.github.com/DougGregor/92a2e4f6e11f6d733fb5065e9d1c880f
    //
    func asyncMap<T: Sendable>(nWorkers requestedNWorkers: Int? = nil, delay: Double? = nil, _ transform: @escaping @Sendable (Element, Int) async throws -> T) async throws -> [T] {
        let nWorkers = requestedNWorkers ?? DEFAULT_N_WORKERS

        let n = self.count
        if n == 0 {
            return []
        }

        return try await withThrowingTaskGroup(of: (Int, Int, T).self, returning: [T].self) { group in
            var result = Array<T?>(repeatElement(nil, count: n))

            var i = self.startIndex
            var submitted = 0

            func submitNext(_ workerIndex: Int? = nil) async throws {
                if i == self.endIndex { return }

                let unwrappedWorkerIndex = workerIndex ?? submitted
                let element = self[i]

                group.addTask { [submitted, unwrappedWorkerIndex, element] in
                    let value = try await transform(element, unwrappedWorkerIndex)
                    return (submitted, unwrappedWorkerIndex, value)
                }

                if let unwrappedDelay = delay {
                    usleep(UInt32(unwrappedDelay * 1_000_000))
                }

                submitted += 1
                formIndex(after: &i)
            }

            // submit first initial tasks

            for _ in 0..<nWorkers {
                try await submitNext()
            }

            // as each task completes, submit a new task until we run out of work

            for try await (index, workerIndex, taskResult) in group {
                result[index] = taskResult
                try Task.checkCancellation()
                try await submitNext(workerIndex)
            }

            assert(result.count == n)
            return Array(result.compactMap { $0 })
        }
    }
}

struct Queue<T> { 
    private var list = [T]() 

    var isEmpty: Bool { return self.list.isEmpty } 
    var front: T? { return self.list.first } 

    mutating func enqueue(_ item: T) { 
        self.list.append(item) 
    } 

    mutating func enqueue(contentsOf items: [T]) { 
        self.list.append(contentsOf: items) 
    } 

    mutating func dequeue() -> T? { 
        guard self.isEmpty == false else { return nil } 
        return self.list.removeFirst() 
    }
}

enum TaskExecitionError<Element>: Error {
    case taskHasFailed(item: Element, index: [Int], workerIndex: Int, reason: Error, retry: Bool) 
    case stopIteration(item: Element, index: [Int], workerIndex: Int, reason: Error, retry: Bool) 
}

public extension IteratorProtocol {
    typealias TruncatedElement = (item: Element, index: [Int])

    mutating func asyncDo<T: Sendable> (
        nWorkers requestedNWorkers: Int? = nil, delay: Double? = nil,
        transform: @escaping @Sendable (_ item: Element, _ workerIndex: Int, _ index: [Int]) async throws -> T,
        until shouldStop: @escaping @Sendable (T, [Int]) async throws -> Bool = {(_, _) in false},
        truncateElement: @escaping @Sendable (_ item: Element, _ index: [Int]) throws -> [TruncatedElement]
    ) async throws -> [T] {
        let nWorkers = requestedNWorkers ?? DEFAULT_N_WORKERS

        return try await withThrowingTaskGroup(of: ([Int], Int, T).self, returning: [T].self) { group in
            var result = [(index: [Int], item: T)]()

            var submitted = 0
            var truncatedElements = Queue<TruncatedElement>() // [TruncatedElement]()

            func submitNext(_ workerIndex: Int? = nil) async throws {
                // if try await shouldStop() { return false }

                let unwrappedWorkerIndex = workerIndex ?? submitted
                
                if let truncatedElement = truncatedElements.dequeue() {
                    let item = truncatedElement.item
                    let index = truncatedElement.index

                    // print("Fetched truncated element with index \(index)")

                    group.addTask { [submitted, unwrappedWorkerIndex, item] in
                        let value = try await transform(item, unwrappedWorkerIndex, index)
                        return (index, unwrappedWorkerIndex, value)
                    }
                } else {
                    let item = next()!

                    group.addTask { [submitted, unwrappedWorkerIndex, item] in
                        let value = try await transform(item, unwrappedWorkerIndex, [submitted])
                        return ([submitted], unwrappedWorkerIndex, value)
                    }

                    submitted += 1
                }

                if let unwrappedDelay = delay {
                    usleep(UInt32(unwrappedDelay * 1_000_000))
                }

            }

            // submit first initial tasks

            for _ in 0..<nWorkers {
                _ = try await submitNext()
            }

            // as each task completes, submit a new task until we run out of work

            var continueSubmittingTasks = true
            var gotStopIterationMarker = false
            var nConsecutiveErrors = 0 // TODO: Implement a task submission rate reduction strategy

            while continueSubmittingTasks {
                // print("Submitting tasks...")
                if gotStopIterationMarker {
                    continueSubmittingTasks = false
                }

                do {
                    for try await (index, workerIndex, taskResult) in group {
                        result.append((index: index, item: taskResult))

                        try Task.checkCancellation()

                        if try await shouldStop(taskResult, index) {
                            continueSubmittingTasks = false
                            break
                        }

                        if nConsecutiveErrors > 0 {
                            nConsecutiveErrors = 0
                        }

                        _ = try await submitNext(workerIndex)
                    }
                } catch {
                    nConsecutiveErrors += 1

                    // print("Task execution error: \(error)")

                    if case TaskExecitionError<Element>.stopIteration(let item, let index, _, _, _) = error {
                        // print("Stop iteration after task = \(index), item = \(item)")
                        gotStopIterationMarker = true
                    } else if case TaskExecitionError<Element>.taskHasFailed(let item, let index, let workerIndex, _, let retry) = error {
                        // print("Index of failed task = \(index), item = \(item)")

                        if retry {
                            let truncated = try truncateElement(item, index)
                            // print("Repeating with truncated elements \(truncated)")

                            truncatedElements.enqueue(contentsOf: truncated)
                        } else {
                            throw error
                        }

                        // print("Submitting next task instead of failed one")
                        _ = try await submitNext(workerIndex)
                    } else {
                        // truncatedElements.enqueue(contentsOf: truncateElement(
                        throw error
                    }
                }
            }

            return try await result.sorted{
                for i in 0..<[$0.index.count, $1.index.count].min()! {
                    if $0.index[i] < $1.index[i] {
                       return true
                    } else if $0.index[i] > $1.index[i] {
                        return false
                    } 
                } 

                return $0.index.count < $1.index.count
            }.map{$0.item}
        }
    }
}

// public struct AsyncIteratorMapper<T> {
//     public let nWorkers: Int?
//     public let delay: Double?
//     public let shouldStop: (T, Int) async throws -> Bool
// 
//     public init(nWorkers: Int? = nil, delay: Double? = nil, until shouldStop: @escaping @Sendable (T, Int) async throws -> Bool) {
//         self.nWorkers = nWorkers
//         self.delay = delay
//         self.shouldStop = shouldStop
// 
//         // try await withThrowingTaskGroup(of: (Int, Int, T).self, returning: [T].self) { group in
//     }
// 
// }
