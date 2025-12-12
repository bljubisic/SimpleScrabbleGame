//
//  AppModel.swift
//  SimpleScrabbleGame
//
//  Created by Bratislav Ljubisic Home  on 6/26/25.
//

import SwiftUI
import RealityKit

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    enum Level: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }
}

let BASE_TILES_NUM: Int = 15
let SUBLEVELS_PER_LEVEL: Int = 10
let BASE_WORD_LENGTH: Int = 3

let levelMultiplier: [AppModel.Level: Int] = [
    .easy: 1,
    .medium: 2,
    .hard: 3
]

// Scrabble letter point values
let letterValues: [String: Int] = [
    "A": 1, "E": 1, "I": 1, "O": 1, "U": 1, "L": 1, "N": 1, "S": 1, "T": 1, "R": 1,
    "D": 2, "G": 2,
    "B": 3, "C": 3, "M": 3, "P": 3,
    "F": 4, "H": 4, "V": 4, "W": 4, "Y": 4,
    "K": 5,
    "J": 8, "X": 8,
    "Q": 10, "Z": 10
]

// Letter distribution (simplified Scrabble distribution)
let letterDistribution: [String: Int] = [
    "A": 9, "B": 2, "C": 2, "D": 4, "E": 12, "F": 2, "G": 3, "H": 2, "I": 9, "J": 1,
    "K": 1, "L": 4, "M": 2, "N": 6, "O": 8, "P": 2, "Q": 1, "R": 6, "S": 4, "T": 6,
    "U": 4, "V": 2, "W": 2, "X": 1, "Y": 2, "Z": 1
]

struct LetterTileModel: Identifiable {
    let id: UUID
    var position: SIMD3<Float>
    var isSelected: Bool
    let letter: String
    let value: Int
    let cube: Entity
}

struct BallModel: Identifiable {
    let id: UUID
    var position: SIMD3<Float>
    var pickedUp: Bool
    let color: UIColor
    let letter: String
    let sphere: Entity
}

extension LetterTileModel {
    static let letterTileSelectedLens = Lens<LetterTileModel, Bool>(
        get: { $0.isSelected },
        set: { isSelected, tileModel in
            LetterTileModel(id: tileModel.id, position: tileModel.position, isSelected: isSelected, letter: tileModel.letter, value: tileModel.value, cube: tileModel.cube)
        }
    )
}

struct Game {
    var level: AppModel.Level
    var subLevel: Int
    let keptTimePerLevel: [String: TimeInterval]
    let targetWord: String
    let wordsFormed: [String]
}

extension Game {
    init() {
        self.level = .easy
        self.subLevel = 0
        self.keptTimePerLevel = [:]
        self.targetWord = ""
        self.wordsFormed = []
    }

    init (level: AppModel.Level, subLevel:Int, keepTimePerLevel: [String: TimeInterval], targetWord: String, wordsFormed: [String]) {
        self.level = level
        self.subLevel = subLevel
        self.keptTimePerLevel = keepTimePerLevel
        self.targetWord = targetWord
        self.wordsFormed = wordsFormed
    }

    init(level: AppModel.Level, subLevel: Int) {
        self.level = level
        self.subLevel = subLevel
        self.keptTimePerLevel = [:]
        self.targetWord = ""
        self.wordsFormed = []
    }
}
extension Game {
    static let gameLevelLens = Lens<Game, AppModel.Level>(
        get: { $0.level },
        set: { level, game in
            Game(level: level, subLevel: game.subLevel, keepTimePerLevel: [:], targetWord: "", wordsFormed: [])
        }
    )

    static let gameTimePerLevelLens = Lens<Game, [String: TimeInterval]>(
        get: { $0.keptTimePerLevel },
        set: { keptTimePerLevel, game in
            Game(level: game.level, subLevel: game.subLevel, keepTimePerLevel: keptTimePerLevel, targetWord: game.targetWord, wordsFormed: game.wordsFormed)
        }
    )

    static let gameSubLevelLens = Lens<Game, Int>(
        get: { $0.subLevel },
        set: { subLevel, game in
            Game(level: game.level, subLevel: subLevel, keepTimePerLevel: game.keptTimePerLevel, targetWord: game.targetWord, wordsFormed: game.wordsFormed)
        }
    )
}

class CurrentGameState: ObservableObject {
    @Published var game: Game
    @Published var letterTileModels: [LetterTileModel]
    @Published var ballModels: [BallModel] = []

    init() {
        self.game = Game()
        self.letterTileModels = []
        self.ballModels = []
    }

    init(game: Game) {
        self.game = game
        self.letterTileModels = []
        self.ballModels = []
    }

    init(game: Game, letterTileModels: [LetterTileModel]) {
        self.game = game
        self.letterTileModels = letterTileModels
        self.ballModels = []
    }
}

extension CurrentGameState {
    static let currentGameGameLens = Lens<CurrentGameState, Game>(
        get: { $0.game },
        set: { game, currentGameState in
            CurrentGameState(game: game, letterTileModels: currentGameState.letterTileModels)
        }
    )

    static let currentGameLetterTileModelsLens = Lens<CurrentGameState, [LetterTileModel]>(
        get: { $0.letterTileModels },
        set: { letterTileModels, currentGameState in
            CurrentGameState(game: currentGameState.game, letterTileModels: letterTileModels)
        }
    )
}

struct Lens<Whole, Part> {
    let get: (Whole) -> Part
    let set: (Part, Whole) -> Whole
}


