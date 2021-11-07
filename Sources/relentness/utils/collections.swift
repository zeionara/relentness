public extension Array {
    public func groups(nChunks: Int, nElementsPerChunk: Int, nRemainingElements: Int) -> [[Element]] {
        let shouldPutAnAdditionalElement = (0..<nChunks).map{$0 < nRemainingElements}

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

    public func groups(nChunks: Int) -> [[Element]] {
        assert(0 < nChunks && nChunks <= count)

        let nElementsPerChunk = count / nChunks
        let nRemainingElements = count % nChunks

        return groups(nChunks: nChunks, nElementsPerChunk: nElementsPerChunk, nRemainingElements: nRemainingElements)
    }

    public func groups(nElementsPerChunk: Int) -> [[Element]] {
        assert(0 < nElementsPerChunk && nElementsPerChunk <= count)

        let nChunks = count / nElementsPerChunk
        let nRemainingElements = count % nElementsPerChunk

        return groups(nChunks: nChunks, nElementsPerChunk: nElementsPerChunk, nRemainingElements: nRemainingElements)
    }
}

