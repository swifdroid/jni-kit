//
//  JClassName.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A model for constructing Java class names in JNI-compatible format.
///
/// Supports slash-separated (`/`) names for packages and dollar-separated (`$`) inner classes.
open class JClassName: @unchecked Sendable, ExpressibleByStringLiteral {
    /// Parent class or package (can be nil for root)
    public let parent: JClassName?

    /// Current class segment (e.g. `"Build"` or `"LinearLayout"`)
    public let name: String

    /// Whether this component is an inner class (`$`) or nested under package (`/`)
    public let isInnerClass: Bool

    /// Full JNI-compatible class path (e.g. `"android/os/Build$VERSION"`)
    public let path: String

    /// Fully qualified name with dots, e.g. "java.lang.String"
    public let fullName: String

    /// Initialize from a root name (e.g. `"java"`, `"android"`)
    required public init(stringLiteral: String) {
        self.parent = nil
        #if canImport(FoundationEssentials)
        self.name = (stringLiteral.components(separatedBy: "/").last ?? stringLiteral).replacing(";", with: "")
        #else
        self.name = (stringLiteral.components(separatedBy: "/").last ?? stringLiteral).replacingOccurrences(of: ";", with: "")
        #endif
        self.isInnerClass = stringLiteral.contains("$")
        self.path = stringLiteral
        let isArray = stringLiteral.hasPrefix("[L") && stringLiteral.hasSuffix(";")
        #if canImport(FoundationEssentials)
        self.fullName = stringLiteral.components(separatedBy: "/").joined(separator: ".").replacing("[L", with: "").replacing(";", with: isArray ? "[]" : "")
        #else
        self.fullName = stringLiteral.components(separatedBy: "/").joined(separator: ".").replacingOccurrences(of: "[L", with: "").replacingOccurrences(of: ";", with: isArray ? "[]" : "")
        #endif
    }

    /// Initialize from a parent and class segment, specifying whether it's an inner class.
    public init(parent: JClassName, name: String, isInnerClass: Bool = false, asArray: Bool = false) {
        self.parent = parent
        self.name = name.components(separatedBy: "/").last ?? name
        self.isInnerClass = isInnerClass
        let separator = isInnerClass ? "$" : "/"
        let path = parent.path + separator + name
        self.path = asArray ? "[L\(path);" : path
        self.fullName = path.components(separatedBy: "/").joined(separator: ".")
    }

    /// Create a new `JClassName` representing this class as an array type.
    public func asArray() -> JClassName {
        JClassName(stringLiteral: "[L\(path);")
    }
}

extension JClassName: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    public static func == (lhs: JClassName, rhs: JClassName) -> Bool {
        return lhs.path == rhs.path
    }
}

extension JClassName: CustomStringConvertible {
    public var description: String { path }
}
