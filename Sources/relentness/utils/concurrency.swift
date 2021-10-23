let DEFAULT_N_WORKERS = 2

extension Collection {
    //
    // Taken from https://gist.github.com/DougGregor/92a2e4f6e11f6d733fb5065e9d1c880f
    //
    func asyncMap<T>(nWorkers requestedNWorkers: Int? = nil, _ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        let nWorkers = requestedNWorkers ?? DEFAULT_N_WORKERS

        let n = self.count
        if n == 0 {
            return []
        }

        // return try await Task.withGroup(resultType: (Int, T).self) { group in
        return try await withThrowingTaskGroup(of: (Int, T).self, returning: [T].self) { group in
            var result = Array<T?>(repeatElement(nil, count: n))

            var i = self.startIndex
            var submitted = 0

            func submitNext() async throws {
                if i == self.endIndex { return }

                group.addTask { [submitted, i] in
                    let value = try await transform(self[i])
                    return (submitted, value)
                }
                submitted += 1
                formIndex(after: &i)
            }

            // submit first initial tasks
            for _ in 0..<nWorkers {
                try await submitNext()
            }

            // as each task completes, submit a new task until we run out of work
            while let (index, taskResult) = try! await group.next() {
                result[index] = taskResult

                try Task.checkCancellation()
                try await submitNext()
            }

            assert(result.count == n)
            return Array(result.compactMap { $0 })
        }
    }
}

