import Foundation
#if canImport(UIKit)
import UIKit
#endif

// Test script to verify improved word validation logic
class ImprovedWordValidationTester {
    
    static func testImprovedValidation() {
        print("=== Improved Word Validation Test ===\n")
        
        // Simulate the validation logic from GameState
        let tester = ValidationTester()
        
        // Test 1: Length validation
        print("1. LENGTH VALIDATION TESTS:")
        let lengthTests = [
            ("", "Empty string"),
            ("a", "Single letter"),
            ("ab", "Two letters"),
            ("cat", "Three letters (valid)"),
            ("test", "Four letters (valid)")
        ]
        
        for (word, description) in lengthTests {
            let result = tester.validateWord(word)
            print("  '\(word)' (\(description)): \(result.rawValue) - \(result.message)")
        }
        
        // Test 2: Character validation (Scrabble rules)
        print("\n2. CHARACTER VALIDATION TESTS:")
        let charTests = [
            ("hello", "All letters (valid)"),
            ("123", "Numbers only"),
            ("test123", "Mixed letters and numbers"),
            ("hello!", "Letters with punctuation"),
            ("café", "Letters with accents (valid)"),
            ("naïve", "Letters with diaeresis (valid)"),
            ("co-op", "Letters with hyphen"),
            ("it's", "Letters with apostrophe")
        ]
        
        for (word, description) in charTests {
            let result = tester.validateWord(word)
            print("  '\(word)' (\(description)): \(result.rawValue) - \(result.message)")
        }
        
        // Test 3: Dictionary validation
        print("\n3. DICTIONARY VALIDATION TESTS:")
        let dictTests = [
            ("cat", "Valid English word"),
            ("xyz", "Invalid letter combination"),
            ("qqq", "Invalid repeated letters"),
            ("the", "Valid short word"),
            ("computer", "Valid long word"),
            ("abcdefg", "Invalid alphabet sequence")
        ]
        
        for (word, description) in dictTests {
            let result = tester.validateWord(word)
            print("  '\(word)' (\(description)): \(result.rawValue) - \(result.message)")
        }
        
        // Test 4: Duplicate word validation
        print("\n4. DUPLICATE WORD TESTS:")
        tester.addUsedWord("cat")
        tester.addUsedWord("dog")
        
        let dupTests = [
            ("cat", "Already used (lowercase)"),
            ("CAT", "Already used (uppercase)"),
            ("Cat", "Already used (mixed case)"),
            ("mouse", "Not used yet")
        ]
        
        for (word, description) in dupTests {
            let result = tester.validateWord(word)
            print("  '\(word)' (\(description)): \(result.rawValue) - \(result.message)")
        }
        
        // Test 5: Language detection and fallback
        print("\n5. LANGUAGE DETECTION TESTS:")
        print("  Current locale: \(Locale.current.identifier)")
        print("  Best available language: \(tester.getBestAvailableLanguage())")
        
        #if canImport(UIKit)
        print("  Available languages count: \(UITextChecker.availableLanguages.count)")
        print("  Sample languages: \(Array(UITextChecker.availableLanguages.prefix(5)))")
        #endif
    }
}

// Validation result enum (mirroring GameState)
enum TestWordValidationResult: String {
    case valid = "✓ VALID"
    case tooShort = "✗ TOO SHORT"
    case containsInvalidCharacters = "✗ INVALID CHARS"
    case notInDictionary = "✗ NOT IN DICTIONARY"
    case alreadyUsed = "✗ ALREADY USED"
    
    var message: String {
        switch self {
        case .valid:
            return "Word is valid"
        case .tooShort:
            return "Word must be at least 3 letters"
        case .containsInvalidCharacters:
            return "Word must contain only letters"
        case .notInDictionary:
            return "Word not found in dictionary"
        case .alreadyUsed:
            return "Word already used this game"
        }
    }
}

// Test implementation of validation logic
class ValidationTester {
    private var wordsFormed: [String] = []
    
    func addUsedWord(_ word: String) {
        wordsFormed.append(word)
    }
    
    func validateWord(_ word: String) -> TestWordValidationResult {
        // Check minimum length
        guard word.count >= 3 else {
            return .tooShort
        }
        
        // Check if word contains only letters (Scrabble rule)
        let letterCharacterSet = CharacterSet.letters
        let wordCharacterSet = CharacterSet(charactersIn: word.lowercased())
        if !wordCharacterSet.isSubset(of: letterCharacterSet) {
            return .containsInvalidCharacters
        }
        
        // Check if word was already used
        if wordsFormed.contains(where: { $0.lowercased() == word.lowercased() }) {
            return .alreadyUsed
        }
        
        // Check dictionary
        if !isWordInDictionary(word) {
            return .notInDictionary
        }
        
        return .valid
    }
    
    func isWordInDictionary(_ word: String) -> Bool {
        #if canImport(UIKit)
        let checker = UITextChecker()
        let languageCode = getBestAvailableLanguage()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: languageCode
        )
        return misspelledRange.location == NSNotFound
        #else
        // Fallback for macOS testing - accept common words
        let commonWords = ["cat", "dog", "the", "computer", "hello", "test", "café", "naïve"]
        return commonWords.contains(word.lowercased())
        #endif
    }
    
    func getBestAvailableLanguage() -> String {
        #if canImport(UIKit)
        let availableLanguages = UITextChecker.availableLanguages
        
        if let currentLanguage = Locale.current.language.languageCode?.identifier {
            // First, try exact match
            if availableLanguages.contains(currentLanguage) {
                return currentLanguage
            }
            
            // Try base language code
            let baseLanguage = String(currentLanguage.prefix(2))
            if availableLanguages.contains(baseLanguage) {
                return baseLanguage
            }
            
            // Try any variant
            if let variant = availableLanguages.first(where: { $0.hasPrefix(baseLanguage) }) {
                return variant
            }
        }
        #endif
        return "en"
    }
}

// Run the tests
ImprovedWordValidationTester.testImprovedValidation()