public extension String {
    var rows: [String] {
        self.components(separatedBy: "\n")
    }

    var tabSeparatedValues: [String] {
        self.components(separatedBy: "\t")
    }

    var asDouble: Double {
        Double(self)!
    }
}

