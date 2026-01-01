import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

// Cross-platform word validation implementation
class CrossPlatformWordValidator {
    
    static func isValidWord(_ word: String, language: String = "en") -> Bool {
        guard word.count >= 3 else { return false }
        
        #if os(iOS) || os(visionOS) || os(xrOS)
        // Use UITextChecker for iOS and VisionOS
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )
        return misspelledRange.location == NSNotFound
        
        #elseif os(macOS)
        // Use NSSpellChecker for macOS
        let checker = NSSpellChecker.shared
        checker.setLanguage(language)
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.checkSpelling(
            of: word,
            startingAt: 0,
            language: language,
            wrap: false,
            inSpellDocumentWithTag: 0,
            wordCount: nil
        )
        return misspelledRange.location == NSNotFound
        
        #else
        // Fallback for other platforms
        print("Warning: Spell checking not available on this platform")
        return true
        #endif
    }
    
    static func getAvailableLanguages() -> [String] {
        #if os(iOS) || os(visionOS) || os(xrOS)
        return UITextChecker.availableLanguages
        #elseif os(macOS)
        return NSSpellChecker.shared.availableLanguages
        #else
        return ["en"]
        #endif
    }
    
    static func testValidation() {
        print("=== Cross-Platform Word Validation Test ===\n")
        
        // Platform detection
        #if os(visionOS) || os(xrOS)
        print("Platform: visionOS/xrOS")
        #elseif os(iOS)
        print("Platform: iOS")
        #elseif os(macOS)
        print("Platform: macOS")
        #else
        print("Platform: Unknown")
        #endif
        
        // Available languages
        print("\nAvailable languages:")
        let languages = getAvailableLanguages()
        for lang in languages {
            print("  - \(lang)")
        }
        
        // Current locale language
        let currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        print("\nCurrent device language: \(currentLanguage)")
        print("Is current language available? \(languages.contains(currentLanguage))")
        
        // Use effective language (fallback to "en" if current not available)
        let effectiveLanguage = languages.contains(currentLanguage) ? currentLanguage : "en"
        print("Using language for validation: \(effectiveLanguage)")
        
        // Test words
        print("\n=== Test Word Validation ===")
        let testWords = [
            // English words
            ("cat", "English common word"),
            ("hello", "English greeting"),
            ("the", "English article"),
            ("computer", "English noun"),
            
            // Other language words
            ("bonjour", "French greeting"),
            ("hola", "Spanish greeting"),
            ("guten", "German (part of greeting)"),
            ("ciao", "Italian greeting"),
            
            // Invalid/nonsense words
            ("xyz", "Three random letters"),
            ("qqq", "Repeated letter"),
            ("abcdefg", "Alphabet sequence"),
            
            // Edge cases
            ("a", "Single letter (too short)"),
            ("ab", "Two letters (too short)"),
            ("I", "English pronoun (too short)"),
            
            // Special characters and numbers
            ("123", "Numbers only"),
            ("test123", "Mixed letters and numbers"),
            ("café", "Accented character"),
            ("naïve", "Accented character"),
            ("it's", "Apostrophe"),
            ("co-op", "Hyphen"),
        ]
        
        for (word, description) in testWords {
            let isValid = isValidWord(word, language: effectiveLanguage)
            let status = isValid ? "✓ VALID" : "✗ INVALID"
            print("  '\(word)' (\(description)): \(status)")
        }
        
        // Test language-specific validation if multiple languages available
        if languages.count > 1 {
            print("\n=== Language-Specific Tests ===")
            
            // Test English words with English dictionary
            if languages.contains("en") {
                print("\nEnglish dictionary:")
                let englishWords = ["cat", "dog", "house", "xyz", "qqq"]
                for word in englishWords {
                    let isValid = isValidWord(word, language: "en")
                    print("  '\(word)': \(isValid ? "✓" : "✗")")
                }
            }
            
            // Test Spanish words if Spanish available
            if languages.contains("es") {
                print("\nSpanish dictionary:")
                let spanishWords = ["hola", "casa", "gato", "xyz", "hello"]
                for word in spanishWords {
                    let isValid = isValidWord(word, language: "es")
                    print("  '\(word)': \(isValid ? "✓" : "✗")")
                }
            }
            
            // Test French words if French available
            if languages.contains("fr") {
                print("\nFrench dictionary:")
                let frenchWords = ["bonjour", "maison", "chat", "xyz", "hello"]
                for word in frenchWords {
                    let isValid = isValidWord(word, language: "fr")
                    print("  '\(word)': \(isValid ? "✓" : "✗")")
                }
            }
        }
    }
}

// Run the test
CrossPlatformWordValidator.testValidation()