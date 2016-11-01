import Foundation

//let goal: UInt = UInt.subtractWithOverflow(0, 1).0
let goal: UInt = 4815162342
let populationSize = 10000

let algorithm = GeneticAlgorithm(numberToSolve: goal, populationSize: populationSize)

print("Looking for:\t\t \(goal.asBinaryString)")

while !algorithm.solved {
    algorithm.runGeneration()

    let bestIndividual = algorithm.population.first!
    let fitness = bestIndividual.fitness(towards: goal)
    let fitnessPercentage = Int(Double(fitness) / Double(UInt.numberOfBits) * 100)

    print("Fittest individual:\t \(bestIndividual.number.asBinaryString) (fitness: \(fitnessPercentage)%)")
}

print("!Solved! after \(algorithm.generationNumber) generations")
