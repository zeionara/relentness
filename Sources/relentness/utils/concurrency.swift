let DEFAULT_N_WORKERS = 2

extension Collection where Element: Sendable {
    //
    // Taken from https://gist.github.com/DougGregor/92a2e4f6e11f6d733fb5065e9d1c880f
    //
    func asyncMap<T: Sendable>(nWorkers requestedNWorkers: Int? = nil, _ transform: @escaping @Sendable (Element, Int) async throws -> T) async throws -> [T] {
        let nWorkers = requestedNWorkers ?? DEFAULT_N_WORKERS

        let n = self.count
        if n == 0 {
            return []
        }

        // return try await Task.withGroup(resultType: (Int, T).self) { group in
        return try await withThrowingTaskGroup(of: (Int, Int, T).self, returning: [T].self) { group in
            var result = Array<T?>(repeatElement(nil, count: n))

            var i = self.startIndex
            var submitted = 0
            // var freeWorkerIndices = Set(0..<nWorkers)

            func submitNext(_ workerIndex: Int? = nil) async throws {
                if i == self.endIndex { return }

                let unwrappedWorkerIndex = workerIndex ?? submitted
                let element = self[i]

                group.addTask { [submitted, unwrappedWorkerIndex, element] in
                    print("Getting value \(submitted)")
                    let value = try await transform(element, unwrappedWorkerIndex)
                    print("Got value \(submitted)")
                    return (submitted, unwrappedWorkerIndex, value)
                }

                // freeWorkerIndices.remove(submitted)
                submitted += 1
                formIndex(after: &i)
            }

            // submit first initial tasks
            print("Submitting initial tasks...")
            for _ in 0..<nWorkers {
                try await submitNext()
            }

            // as each task completes, submit a new task until we run out of work
            print("Waiting for submitted tasks to complete (already collected \(result.compactMap{ $0 }.count) results)...")
            // while let (index, workerIndex, taskResult) = try? await group.next() {
            for try await (index, workerIndex, taskResult) in group {
                result[index] = taskResult

                print("Checking cancellation...")
                try Task.checkCancellation()
                print("Submitting next...")

                try await submitNext(workerIndex)

                // if i < self.endIndex {
                //     let element = self[i]

                //     group.addTask { [submitted, workerIndex] in
                //         print("Getting value \(submitted)...")
                //         let value = try await transform(element, workerIndex)
                //         print("Got value \(submitted)")
                //         return (submitted, workerIndex, value)
                //     }

                //     submitted += 1
                //     formIndex(after: &i)
                // }

                print("Submitted next")
                print("Is empty: \(group.isEmpty)")
            }

            assert(result.count == n)
            return Array(result.compactMap { $0 })
        }
    }
}

