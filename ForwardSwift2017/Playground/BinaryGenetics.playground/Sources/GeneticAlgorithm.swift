import Foundation

public typealias Fitness = Int

public final class Individual {
    public let number: UInt

    init(number: UInt) {
        self.number = number
    }
}

/// Attempts to find a number by mutating individual bits
public final class GeneticAlgorithm {
    private static let percentageOfPopulationToDieEachGeneration = 95

    public let numberToSolve: UInt
    public let populationSize: Int

    // Always sorted by decreasing fitness
    public private(set) var population: [Individual]

    public private(set) var generationNumber = 0

    public init(numberToSolve: UInt, populationSize: Int) {
        self.numberToSolve = numberToSolve
        self.populationSize = populationSize

        self.population = GeneticAlgorithm.createRandomPopulation(size: populationSize)
    }

    private static func createRandomPopulation(size: Int) -> [Individual] {
        return (0..<size).map { _ in return Individual(number: 0) }
    }

    public var solved: Bool {
        return self.population.first!.fitness(towards: self.numberToSolve) == UInt.numberOfBits
    }

    public func runGeneration() {
        // 1: Natural selection (survival of the fittest)
        self.population.removeLast(Int(Double(self.population.count) * (Double(GeneticAlgorithm.percentageOfPopulationToDieEachGeneration) / 100)))

        // 2: Random mutations
        let mutationsPerIndividual = Int(Double(self.populationSize - self.population.count) / Double(self.population.count))
        let individualsToMutate = Array(repeating: self.population, count: mutationsPerIndividual).flatMap { $0 }
        let mutated = individualsToMutate.map { $0.mutate() }
        self.population += mutated

        // 3: Sort by fitness
        self.population.sort { $0.fitness(towards: self.numberToSolve) > $1.fitness(towards: self.numberToSolve) }

        generationNumber += 1
    }
}

extension Individual {
    public func fitness(towards goal: UInt) -> Fitness {
        return Fitness(self.number.numberOfBitsEqual(in: goal))
    }
}

extension Individual {
    static let likelyhoodOfMutatingBit = 5

    fileprivate func mutate() -> Individual {
        let mutatedBits = self.number.bits.map { bit -> Bool in
            let shouldMutate = Bool.random(likelyHoodPercentage: Individual.likelyhoodOfMutatingBit)

            return shouldMutate ? !bit : bit
        }
        
        return Individual(number: UInt(bits: mutatedBits))
    }
}
