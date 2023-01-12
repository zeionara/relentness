import Foundation

public extension Array where Element: FloatingPoint {
    // func average() -> Element {
    //     return reduce(0, +) / Double(count)
    // }
    func sum() -> Element {
        return self.reduce(0, +)
    }

    func avg() -> Element {
        if self.count < 2 {
            return self.first ?? Element.nan
        }

        return self.sum() / Element(self.count)
    }

    func std() -> Element {
        if self.count < 2 {
            return 0
        }

        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }

}
