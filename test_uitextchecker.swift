import Foundation
#if canImport(UIKit)
import UIKit
#endif

print("Testing UITextChecker availability...")

#if os(visionOS) || os(xros) || os(xrOS)
print("Platform: visionOS/xrOS")
#elseif os(iOS)
print("Platform: iOS")
#elseif os(macOS)
print("Platform: macOS")
#else
print("Platform: Unknown")
#endif

#if canImport(UIKit)
print("UIKit is available")
    #if os(iOS) || os(visionOS) || os(xros) || os(xrOS)
    print("UITextChecker should be available on this platform")
    // Test if we can instantiate UITextChecker
    let _ = UITextChecker()
    print("✓ UITextChecker instantiated successfully")
    #endif
#else
print("UIKit is NOT available")
#endif

#if os(macOS)
import AppKit
print("On macOS, should use NSSpellChecker instead")
#endif
