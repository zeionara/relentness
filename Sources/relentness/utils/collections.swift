public extension Array {
    func groupsWithExtension(nChunks: Int, nElementsPerChunk: Int, nRemainingElements: Int) -> [[Element]] {
        // nChunks will be preserved, remaining elements will be distributed among the given chunks (nRemainingElements must be <= nChunks)
        // print("Count = \(count)")
        // print("N elements per chunk = \(nElementsPerChunk)")
        // print("N remaining elements = \(nRemainingElements)")
        // print("Calculated count = \(nElementsPerChunk * nChunks + nRemainingElements)")
        assert(nRemainingElements <= nChunks)
        
        let shouldPutAnAdditionalElement = (0..<nChunks).map{$0 < nRemainingElements}

        // print((0..<nChunks).map{$0})

        var currentIndex = 0
        var chunks = [[Element]]()

        for i in 0..<nChunks {
            let nextIndex = currentIndex + nElementsPerChunk + (shouldPutAnAdditionalElement[i] ? 1 : 0)
            let currentChunk = Array(self[currentIndex..<nextIndex])

            chunks.append(currentChunk)
            currentIndex = nextIndex
        }

        // print(chunks.count)
        // print(chunks.map{$0.count}.reduce(0, +))
        // print(count)
        assert(chunks.map{$0.count}.reduce(0, +) == count)

        return chunks
    }

    func groupsWithAddition(nChunks: Int, nElementsPerChunk: Int, nRemainingElements: Int) -> [[Element]] {
        // remaining elements will be put into a separate chunk thus increasing nChunks by 1 (nRemainingElements must be <= nElementsPerChunk)
        // print("Count = \(count)")
        // print("N elements per chunk = \(nElementsPerChunk)")
        // print("N remaining elements = \(nRemainingElements)")
        // print("Calculated count = \(nElementsPerChunk * nChunks + nRemainingElements)")
        assert(nRemainingElements <= nElementsPerChunk)
        
        // print((0..<nChunks).map{$0})

        var currentIndex = 0
        var chunks = [[Element]]()

        for _ in 0..<nChunks {
            let nextIndex = currentIndex + nElementsPerChunk
            let currentChunk = Array(self[currentIndex..<nextIndex])

            chunks.append(currentChunk)
            currentIndex = nextIndex
        }

        chunks.append(Array(self[currentIndex..<(currentIndex + nRemainingElements)]))

        // print(chunks.count)
        // print(chunks.map{$0.count}.reduce(0, +))
        // print(count)
        assert(chunks.map{$0.count}.reduce(0, +) == count)

        return chunks
    }

    func groups(nChunks: Int, nElementsPerChunk: Int, nRemainingElements: Int) -> [[Element]] {
        print("Count = \(count)")
        print("N elements per chunk = \(nElementsPerChunk)")
        print("N remaining elements = \(nRemainingElements)")
        print("Calculated count = \(nElementsPerChunk * nChunks + nRemainingElements)")
        
        let shouldPutAnAdditionalElement = (0..<nChunks).map{$0 < nRemainingElements}

        print((0..<nChunks).map{$0})

        var currentIndex = 0
        var chunks = [[Element]]()

        for i in 0..<nChunks {
            let nextIndex = currentIndex + nElementsPerChunk + (shouldPutAnAdditionalElement[i] ? 1 : 0)
            let currentChunk = Array(self[currentIndex..<nextIndex])

            chunks.append(currentChunk)
            currentIndex = nextIndex
        }

        print(chunks.count)
        print(chunks.map{$0.count}.reduce(0, +))
        print(count)
        assert(chunks.map{$0.count}.reduce(0, +) == count)

        return chunks
    }

    func groups(nChunks: Int) -> [[Element]] {
        assert(0 < nChunks && nChunks <= count)

        let nElementsPerChunk = count / nChunks
        let nRemainingElements = count % nChunks

        return groupsWithExtension(nChunks: nChunks, nElementsPerChunk: nElementsPerChunk, nRemainingElements: nRemainingElements)
    }

    func groups(nElementsPerChunk: Int) -> [[Element]] {
        assert(0 < nElementsPerChunk && nElementsPerChunk <= count)

        let nChunks = count / nElementsPerChunk
        let nRemainingElements = count % nElementsPerChunk

        // nChunks += nRemainingElements / nChunks
        // nRemainingElements = count % nChunks

        return groupsWithAddition(nChunks: nChunks, nElementsPerChunk: nElementsPerChunk, nRemainingElements: nRemainingElements)
    }
}

let PLATFORM_CODING_USER_INFO_KEY = CodingUserInfoKey(rawValue: "platform")!

public extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    func postProcess(_ value: String) -> String {
        if let platform = self[PLATFORM_CODING_USER_INFO_KEY] as? Platform {
            if platform == .grapex {
                return value.fromCamelCaseToSnakeCase().atom
            }
        }
        return value.fromCamelCaseToKebabCase()
    }

    func postProcessBool(_ value: Bool) -> Encodable {
        return value
        // if let platform = self[PLATFORM_CODING_USER_INFO_KEY] as? Platform {
        //     if platform == .grapex {
        //         return String(value).atom
        //     }
        // }
        // return value
    }
}
