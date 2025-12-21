//
//  GameState.swift
//  SimpleScrabbleGame
//
//  Created by Bratislav Ljubisic Home  on 7/8/25.
//
import Foundation
import SwiftUI
import RealityKit

public enum GameLevel: Int, CaseIterable, Codable, Comparable {
    case easy = 0
    case medium = 1
    case hard = 2

    // Comparable conformance for `level <= currentLevel` checks
    public static func < (lhs: GameLevel, rhs: GameLevel) -> Bool { lhs.rawValue < rhs.rawValue }
    
    var title: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }
    
    var numberOfSpheres: Int {
        switch self {
        case .easy:
            return 15
        case .medium:
            return 12
        case .hard:
            return 10
        }
    }

    var timeLimit: Double {
        switch self {
        case .easy:
            return 120.0  // 2 minutes
        case .medium:
            return 90.0   // 1.5 minutes
        case .hard:
            return 60.0   // 1 minute
        }
    }
}

struct Score: Codable {
    let points: Int
    let wordsFormed: Int
    let timeStamp: Date
    let selectedLevel: GameLevel
}

class GameState: ObservableObject {

// Conformance added below via extension to avoid platform issues
    
    @Published var selectedLevel: GameLevel = .easy
    @Published var isGameComplete = false
    @Published var currentGame: CurrentGameState = .init()
    @Published var timeRemaining: Double = 0
    @Published var currentScore: Int = 0
    @Published var isTimerRunning = false
    @Published var scores: [Score] = []
    @Published var selectedSpheres: [BallModel] = []
    @Published var wordsFormed: [String] = []
    @Published var currentWord: String = ""

    private var anchorEntity: AnchorEntity?
    private var timer: Timer?
    private var allSpheres: [BallModel] = []
    
    #if os(visionOS)
    func setupScene(content: RealityViewContent, attachments: RealityViewAttachments) {
        self.timeRemaining = self.selectedLevel.timeLimit

        anchorEntity = AnchorEntity(.head, trackingMode: .once)

        loadScores()
        content.add(anchorEntity!)

        if let instructions = attachments.entity(for: "Instructions") {
            instructions.position = SIMD3(1, 1.8, -1)
            content.add(instructions)
        }
        if let gameComplete = attachments.entity(for: "game-complete")  {
            gameComplete.position.z -= 1
            gameComplete.position.y += 2
            gameComplete.position.x -= 0
            content.add(gameComplete)
        }
        createInitialSpheres()
    }
#else
    // Non-visionOS stub so the file compiles on iOS/macOS. Use populateScene(root:) instead.
    func setupScene() {
        self.timeRemaining = self.selectedLevel.timeLimit
        anchorEntity = AnchorEntity(world: .zero)
        createInitialSpheres()
    }
#endif

    private func loadScores() {
        if let scoresData = UserDefaults.standard.data(forKey: "scores"),
           let loadedScores = try? JSONDecoder().decode([Score].self, from: scoresData) {
            self.scores = loadedScores
        } else {
            self.scores = []
        }
    }

    #if os(visionOS)
    func updateScene(content: RealityViewContent, attachments: RealityViewAttachments) {
        // Apply attachment to instruction entity if available
        if let instructions = attachments.entity(for: "Instructions") {
            // Try to get the attachment and apply it to our entity
            for entity in content.entities {
                if entity.name == "instruction-text" {
                    // Copy attachment components to our positioned entity
                    instructions.components = entity.components
                }
            }
        }
        
        // Handle game complete overlay
        if let gameComplete = attachments.entity(for: "game-complete") {
            gameComplete.position = SIMD3(0, 1.7, -1)
            content.add(gameComplete)
        }
    }
#else
    // Non-visionOS stub for parity. Nothing to update for attachments on non-visionOS.
    func updateScene() { }
#endif
    
    func getColorOfEntity(_ entity: Entity) -> UIColor {
        return self.allSpheres.first(where: { $0.sphere == entity })?.color ?? .white
    }

    // Sphere selection/deselection
    func toggleSphereSelection(_ entity: Entity) {
        if let index = selectedSpheres.firstIndex(where: { $0.sphere == entity }) {
            // Deselect sphere
            selectedSpheres.remove(at: index)
        } else if let sphere = allSpheres.first(where: { $0.sphere == entity }) {
            // Select sphere
            selectedSpheres.append(sphere)
        }
        updateCurrentWord()
    }

    private func updateCurrentWord() {
        currentWord = selectedSpheres.map { $0.letter }.joined()
    }

    func clearSelection() {
        selectedSpheres.removeAll()
        currentWord = ""
    }

    func removeAllSpheresFromParent() {
        allSpheres.forEach { $0.sphere.removeFromParent() }
        allSpheres.removeAll()
    }
    
    func handleTap(on entity: Entity) {
        toggleSphereSelection(entity)
    }

    func submitWord() {
        guard currentWord.count >= 3 else {
            print("Word too short: \(currentWord)")
            return
        }

        guard isValidWord(currentWord) else {
            print("Invalid word: \(currentWord)")
            clearSelection()
            return
        }

        // Calculate score for this word
        let wordScore = calculateWordScore(currentWord)
        currentScore += wordScore
        wordsFormed.append(currentWord)

        // Remove used spheres
        removeSelectedSpheres()

        // Replenish spheres to maintain fixed count
        replenishSpheres()

        // Clear selection
        clearSelection()

        print("Word '\(currentWord)' submitted for \(wordScore) points!")
    }

    private func removeSelectedSpheres() {
        for selectedSphere in selectedSpheres {
            selectedSphere.sphere.removeFromParent()
            allSpheres.removeAll { $0.id == selectedSphere.id }
        }
    }

    private func calculateWordScore(_ word: String) -> Int {
        return word.uppercased().reduce(0) { total, letter in
            total + (letterValues[String(letter)] ?? 0)
        }
    }

    private func isValidWord(_ word: String) -> Bool {
        guard word.count >= 3 else { return false }

        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: "en"
        )
        return misspelledRange.location == NSNotFound
    }
    
    func startTimer() {
        isTimerRunning = true
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 0.1
                } else {
                    // Time's up - game over
                    self.timeUp()
                }
            }
        }
    }
    
    func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func timeUp() {
        stopTimer()
        isGameComplete = true

        // Save final score
        let finalScore = Score(
            points: currentScore,
            wordsFormed: wordsFormed.count,
            timeStamp: Date.now,
            selectedLevel: selectedLevel
        )
        saveScore(finalScore)

        removeAllSpheresFromParent()
    }

    private func saveScore(_ score: Score) {
        var scores = self.scores
        scores.append(score)
        if let encodedScores = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encodedScores, forKey: "scores")
            self.scores = scores
        }
    }

    func resetGame() {
        stopTimer()
        isGameComplete = false
        timeRemaining = selectedLevel.timeLimit
        currentScore = 0
        wordsFormed.removeAll()
        clearSelection()
        loadScores()
        removeAllSpheresFromParent()
    }
    
    func createInitialSpheres() {
        removeAllSpheresFromParent()

        let numberOfSpheres = selectedLevel.numberOfSpheres
        let positions = generateNonIntersectingPositions(for: numberOfSpheres)
        let colors = generateRandomColors(count: numberOfSpheres)

        for i in 0..<numberOfSpheres {
            let color = colors[i % colors.count]
            let (sphere, letter) = createSphere(index: i, position: positions[i], useColor: color)
            let uuid = UUID(uuidString: sphere.name) ?? UUID()
            let ballModel = BallModel(id: uuid, position: sphere.position, pickedUp: false, color: color, letter: letter, sphere: sphere)
            currentGame.ballModels.append(ballModel)
            allSpheres.append(ballModel)
            anchorEntity?.addChild(ballModel.sphere)
        }

        startTimer()
    }

    func replenishSpheres() {
        let currentCount = allSpheres.count
        let targetCount = selectedLevel.numberOfSpheres
        let spheresToAdd = targetCount - currentCount

        guard spheresToAdd > 0 else { return }

        let newPositions = generateNonIntersectingPositions(for: spheresToAdd, excluding: allSpheres.map { $0.position })
        let colors = generateRandomColors(count: spheresToAdd)

        for i in 0..<spheresToAdd {
            let color = colors[i % colors.count]
            let (sphere, letter) = createSphere(index: allSpheres.count + i, position: newPositions[i], useColor: color)
            let uuid = UUID(uuidString: sphere.name) ?? UUID()
            let ballModel = BallModel(id: uuid, position: sphere.position, pickedUp: false, color: color, letter: letter, sphere: sphere)
            currentGame.ballModels.append(ballModel)
            allSpheres.append(ballModel)
            anchorEntity?.addChild(ballModel.sphere)
        }
    }
    
    private func createSphere(index: Int, position: SIMD3<Float>, useColor: UIColor) -> (entity: Entity, letter: String) {
        // Create sphere mesh with 10cm radius (0.1 meters)
        let sphereMesh = MeshResource.generateSphere(radius: 0.1)
        // Create material with random color
        let material = SimpleMaterial(
            color: useColor,
            roughness: 0.3,
            isMetallic: false
        )

        // Create model entity
        let sphereEntity = ModelEntity(
            mesh: sphereMesh,
            materials: [material]
        )

        // Set the pre-calculated position
        sphereEntity.position = position
        sphereEntity.name = UUID().uuidString

        // Add some physics for interaction
        sphereEntity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        sphereEntity.components.set(InputTargetComponent())

        // Generate random letter and add it to the sphere
        let randomLetter = generateRandomLetter()
        addLetterToSphere(sphereEntity, letter: randomLetter)

        // Orient sphere so letter faces toward anchor/player (origin)
        // Calculate direction from sphere to origin (where player/anchor is)
        let directionToOrigin = -position // Direction from sphere to origin
        if length(directionToOrigin) > 0.001 {
            // Use lookAt style rotation
            sphereEntity.look(at: SIMD3<Float>(0, 0, 0), from: position, relativeTo: nil)

            // The sphere's UV mapping places the center of the texture on the side
            // Rotate -90 degrees around Y to bring the letter to face the anchor
            let correctionRotation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(0, 1, 0))
            sphereEntity.transform.rotation = sphereEntity.transform.rotation * correctionRotation
        }

#if os(visionOS)
        let hoverComponent = HoverEffectComponent(.spotlight(
            HoverEffectComponent.SpotlightHoverEffectStyle(
                color: useColor, strength: 2.0
            )
        ))
        sphereEntity.components.set(hoverComponent)
#endif

        return (sphereEntity, randomLetter)
    }

    private func generateRandomLetter() -> String {
        let letters = "AAAABCDEEEEEFGHIIIIJKLMNOOOOOPQRSTUUUUVWXYZ"
        return String(letters.randomElement()!)
    }

    private func addLetterToSphere(_ sphere: ModelEntity, letter: String) {
        // Generate a texture with the letter on it
        guard let letterTexture = generateLetterTexture(letter: letter, sphereColor: sphere.model?.materials.first as? SimpleMaterial) else {
            return
        }

        // Update the sphere's material to include the letter texture
        if var material = sphere.model?.materials.first as? SimpleMaterial {
            material.color = .init(tint: .init(cgColor: material.color.tint.cgColor), texture: .init(letterTexture))
            sphere.model?.materials = [material]
        }
    }

    private func generateLetterTexture(letter: String, sphereColor: SimpleMaterial?) -> TextureResource? {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Fill background with sphere's color
            if let color = sphereColor?.color.tint.cgColor {
                context.cgContext.setFillColor(color)
            } else {
                context.cgContext.setFillColor(UIColor.blue.cgColor)
            }
            context.cgContext.fill(CGRect(origin: .zero, size: size))

            // Draw the letter in pure bright white
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 200, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = (letter as NSString).size(withAttributes: attributes)

            // Draw letter only at center so it appears on the front side of sphere
            let position = CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2)
            (letter as NSString).draw(at: position, withAttributes: attributes)
        }

        // Convert UIImage to TextureResource
        guard let cgImage = image.cgImage else { return nil }

        do {
            return try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
        } catch {
            print("Failed to generate texture: \(error)")
            return nil
        }
    }
    
    private func generateNonIntersectingPositions(for numberOfSpheres: Int, excluding excludedPositions: [SIMD3<Float>] = [], isARMode: Bool = false) -> [SIMD3<Float>] {
        var positions: [SIMD3<Float>] = []
        let sphereRadius: Float = 0.1 // 10cm radius
        let minDistance = sphereRadius * 2.4 // Minimum distance between sphere centers with 20% buffer to prevent intersection
        
        // Different positioning for AR vs visionOS
        let baseDistance: Float
        let spreadRadius: Float

        if isARMode {
            // AR mode: position spheres close to the anchor point
            baseDistance = 0.0 // At the anchor
            spreadRadius = 0.5 // Larger spread for AR placement (50cm) to prevent intersection
        } else {
            // visionOS mode: position spheres in front of user
            baseDistance = 1.0 // 1 meter forward
            spreadRadius = 0.5 // 50cm spread radius around the forward point
        }
        
        let maxAttempts = 1000 // Prevent infinite loops
        
        for _ in 0..<numberOfSpheres {
            var attempts = 0
            var validPosition = false
            var newPosition = SIMD3<Float>(0, 0, 0)
            
            while !validPosition && attempts < maxAttempts {
                if isARMode {
                    // AR mode: Generate positions close to anchor
                    newPosition = SIMD3<Float>(
                        Float.random(in: -spreadRadius...spreadRadius), // Left-right
                        Float.random(in: 0.05...spreadRadius), // Above surface
                        Float.random(in: -spreadRadius...spreadRadius) // Forward-back
                    )
                } else {
                    // visionOS mode: Generate random position in a hemisphere in front of user
                    newPosition = SIMD3<Float>(
                        Float.random(in: -spreadRadius...spreadRadius), // Left-right
                        Float.random(in: -spreadRadius/2...spreadRadius), // Slightly up-biased
                        -baseDistance + Float.random(in: -0.4...0.4) // 1m forward ± 20cm
                    )
                }
                
                // Check if this position is far enough from all existing spheres and excluded positions
                validPosition = true
                for existingPosition in positions + excludedPositions {
                    let distance = length(newPosition - existingPosition)
                    if distance < minDistance {
                        validPosition = false
                        break
                    }
                }
                attempts += 1
            }
            
            positions.append(newPosition)
        }
        
        return positions
    }
    
    private func generateRandomColors(count: Int) -> [UIColor] {
        var colors: [UIColor] = []
        let maxAttempts = 10000 // Prevent infinite loops
        let minColorDistance: Float = 0.3 // Minimum distance between colors in RGB space

        while colors.count < count {
            var attempts = 0
            var validColor = false
            var newColor = UIColor.black
            
            while !validColor && attempts < maxAttempts {
                // Generate random color
                let red = Float.random(in: 0.2...1.0)
                let green = Float.random(in: 0.2...1.0)
                let blue = Float.random(in: 0.2...1.0)
                
                newColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
                
                // Check if this color is sufficiently different from existing colors
                validColor = true
                for existingColor in colors {
                    if let existingComponents = existingColor.cgColor.components,
                       existingComponents.count >= 3 {
                        let existingRed = Float(existingComponents[0])
                        let existingGreen = Float(existingComponents[1])
                        let existingBlue = Float(existingComponents[2])
                        
                        // Calculate Euclidean distance in RGB space
                        let distance = sqrt(pow(red - existingRed, 2) +
                                          pow(green - existingGreen, 2) +
                                          pow(blue - existingBlue, 2))
                        
                        if distance < minColorDistance {
                            validColor = false
                            break
                        }
                    }
                }
                attempts += 1
            }
            
            colors.append(newColor)
        }
        
        return colors
    }

}

#if !os(visionOS)
protocol GameStatePopulating {
    func populateScene(root: AnchorEntity)
}
#endif

#if !os(visionOS)
extension GameState: GameStatePopulating {
    func populateScene(root: AnchorEntity) {
        // Set the anchor entity for iOS/AR mode
        self.anchorEntity = root

        // Initialize time remaining for this level
        timeRemaining = selectedLevel.timeLimit

        // Clear previous state
        removeAllSpheresFromParent()
        currentGame.ballModels.removeAll()

        // Generate colors and positions for AR mode
        let numberOfSpheres = selectedLevel.numberOfSpheres
        let positions = generateNonIntersectingPositions(for: numberOfSpheres, isARMode: true)
        let colors = generateRandomColors(count: numberOfSpheres)

        for i in 0..<numberOfSpheres {
            let color = colors[i % colors.count]
            let (sphere, letter) = createSphere(index: i, position: positions[i], useColor: color)
            let uuid = UUID(uuidString: sphere.name) ?? UUID()
            let ballModel = BallModel(id: uuid, position: sphere.position, pickedUp: false, color: color, letter: letter, sphere: sphere)
            currentGame.ballModels.append(ballModel)
            allSpheres.append(ballModel)
            root.addChild(sphere)
        }

        // Start timer for this level
        startTimer()
    }
}
#endif

