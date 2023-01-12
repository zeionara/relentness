import Foundation

public extension Double {
    func round(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

public extension Double {
    func padding(accuracy: Int, toLength newLength: Int, withPad padString: String, startingAt padIndex: Int) -> String {
        return String(format: "%.\(accuracy)f", self).padding(toLength: newLength, withPad: padString, startingAt: padIndex)
    }
}
