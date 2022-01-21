import Foundation

public extension Int {
    func describe(plural: String?, singular: String?, ordinal: Bool = false) -> String {

        // Handle ordinal numerals

        if ordinal {
            if (self % 10 == 1 && self % 100 != 11) {
                return "\(self)st \(singular!)"
            }
            if (self % 10 == 2 && self % 100 != 12) {
                return "\(self)nd \(singular!)"
            }
            if (self % 10 == 3 && self % 100 != 13) {
                return "\(self)rd \(singular!)"
            }
            return "\(self)th \(singular!)"
        }

        // Handle non-ordinal numerals

        if self != 1 {
            return "\(self) \(plural!)"
        }

        if let unwrappedSingular = singular {
            return "\(self) \(unwrappedSingular)"
        }
        return "\(self) \(plural!)"
    }
}

