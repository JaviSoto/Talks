import Foundation

extension UInt {
    init(randomIn range: CountableClosedRange<Int>) {
        self = UInt(arc4random_uniform(UInt32(range.upperBound - range.lowerBound))) + UInt(range.lowerBound)
    }
}

extension Bool {
    static func random(likelyHoodPercentage: Int = 50) -> Bool {
        precondition(likelyHoodPercentage >= 0 && likelyHoodPercentage <= 100)

        return UInt(likelyHoodPercentage) >= UInt(randomIn: 1...100)
    }
}

extension UInt {
    init(bits: [Bool]) {
        var number: UInt = 0
        var exponent: UInt = 0

        for bit in bits.reversed() {
            let bitValue: UInt = bit ? 1 : 0
            number += bitValue * UInt(pow(2, Float(exponent)))

            exponent += 1
        }

        self = number
    }

    var numberOfSetBits: Int {
        var count: Int = 0
        var number = self

        while number > 0 {
            if number.lastBit == 1  {
                count += 1
            }

            number >>= 1
        }

        return count
    }

    var lastBit: UInt {
        return self & 1
    }

    public static var numberOfBits: Int {
        return Int(log2(Double(UInt.max)))
    }

    func numberOfBitsEqual(in number: UInt) -> Int {
        var count: Int = 0

        for (lhs, rhs) in zip(self.bits, number.bits) {
            if lhs == rhs {
                count += 1
            }
        }

        return count
    }

    var bits: [Bool] {
        var bits: [Bool] = []

        var number = self
        var allOnes = UInt.max

        while allOnes > 0 {
            let newBit: Bool

            if number > 0 {
                newBit = number.lastBit == allOnes.lastBit

                number >>= 1
            }
            else {
                newBit = false
            }

            bits.insert(newBit, at: 0)

            allOnes >>= 1
        }

        return bits
    }

    public var asBinaryString: String {
        return self.bits.map { $0 ? "1" : "0" }.joined(separator: "")
    }
}
