//
//  InstructionsTextView.swift
//  SimpleScrabbleGame
//
//  Created by Bratislav Ljubisic Home  on 7/29/25.
//
import SwiftUI


struct InstructionTextView: View {
    @ObservedObject var gameState: GameState
    @State private var showFeedback: Bool = false
    @State private var feedbackMessage: String = ""
    @State private var feedbackColor: Color = .green
    
    var body: some View {
        VStack {
            // Timer
            VStack {
                Text(NSLocalizedString("TIME", comment: "Timer label"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f", gameState.timeRemaining))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(timerColor)
                    .monospacedDigit()
            }
            List(gameState.scores, id: \.timeStamp) { score in
                Text("\(score.selectedLevel.title) - \(score.points)pts (\(score.wordsFormed) words)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            VStack(spacing: 8) {
                Text(NSLocalizedString("Tap letters to spell words!", comment: "Game instruction"))
                    .font(.title)
                Text(String(format: NSLocalizedString("Current Word: %@", comment: "Current word display"), gameState.currentWord.isEmpty ? NSLocalizedString("—", comment: "Empty state") : gameState.currentWord))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                Text(String(format: NSLocalizedString("Score: %d", comment: "Score display"), gameState.currentScore))
                    .font(.headline)
                    .foregroundColor(.yellow)
                Text(String(format: NSLocalizedString("Words: %d", comment: "Word count display"), gameState.wordsFormed.count))
                    .font(.subheadline)
                    .foregroundColor(.green)
                
                // Validation feedback
                if !gameState.validationFeedback.isEmpty {
                    Text(gameState.validationFeedback)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Action buttons for VisionOS
                HStack(spacing: 12) {
                    Button(action: { gameState.clearSelection() }) {
                        Text(NSLocalizedString("Clear", comment: "Clear button"))
                            .fontWeight(.semibold)
                            .frame(minWidth: 100)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                    }
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(gameState.selectedSpheres.isEmpty)
                    .opacity(gameState.selectedSpheres.isEmpty ? 0.5 : 1.0)
                    
                    Button(action: { 
                        // Check if word is valid before submission
                        if gameState.currentWord.count >= 3 {
                            gameState.submitWord()
                        }
                    }) {
                        Text(NSLocalizedString("Submit", comment: "Submit button"))
                            .fontWeight(.bold)
                            .frame(minWidth: 100)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                    }
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(gameState.currentWord.count < 3)
                    .opacity(gameState.currentWord.count < 3 ? 0.5 : 1.0)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: gameState.currentScore)
    }
    
    private var timerColor: Color {
        if gameState.timeRemaining > 5.0 {
            return .green
        } else if gameState.timeRemaining > 2.0 {
            return .orange
        } else {
            return .red
        }
    }
}
