//
//  JClassName.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

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
        self.name = stringLiteral.components(separatedBy: "/").last ?? stringLiteral
        self.isInnerClass = false
        self.path = stringLiteral
        self.fullName = stringLiteral.components(separatedBy: "/").joined(separator: ".")
    }

    /// Initialize from a parent and class segment, specifying whether it's an inner class.
    public init(parent: JClassName, name: String, isInnerClass: Bool = false) {
        self.parent = parent
        self.name = name.components(separatedBy: "/").last ?? name
        self.isInnerClass = isInnerClass
        let separator = isInnerClass ? "$" : "/"
        let path = parent.path + separator + name
        self.path = path
        self.fullName = path.components(separatedBy: "/").joined(separator: ".")
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