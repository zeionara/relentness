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

public extension IteratorProtocol {
    mutating func asyncDo<T: Sendable> (
        nWorkers requestedNWorkers: Int? = nil, delay: Double? = nil,
        transform: @escaping @Sendable (_ item: Element, _ workerIndex: Int, _ index: Int) async throws -> T, until shouldStop: @escaping @Sendable (T) async throws -> Bool
    ) async throws -> [T] {
        let nWorkers = requestedNWorkers ?? DEFAULT_N_WORKERS

        return try await withThrowingTaskGroup(of: (Int, Int, T).self, returning: [T].self) { group in
            var result = [(index: Int, item: T)]()

            var submitted = 0

            func submitNext(_ workerIndex: Int? = nil) async throws {
                // if try await shouldStop() { return false }

                let unwrappedWorkerIndex = workerIndex ?? submitted
                
                let item = next()!

                group.addTask { [submitted, unwrappedWorkerIndex, item] in
                    let value = try await transform(item, unwrappedWorkerIndex, submitted)
                    return (submitted, unwrappedWorkerIndex, value)
                }

                if let unwrappedDelay = delay {
                    usleep(UInt32(unwrappedDelay * 1_000_000))
                }

                submitted += 1
            }

            // submit first initial tasks

            for _ in 0..<nWorkers {
                _ = try await submitNext()
            }

            // as each task completes, submit a new task until we run out of work

            for try await (index, workerIndex, taskResult) in group {
                result.append((index: index, item: taskResult))
                try Task.checkCancellation()

                if try await shouldStop(taskResult) {
                    break
                }

                _ = try await submitNext(workerIndex)
            }

            return try await result.sorted{$0.index < $1.index}.map{$0.item}
        }
    }
}

