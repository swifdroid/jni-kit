//
//  AndroidClassName.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

/// A model for constructing Java class names in JNI-compatible format.
///
/// Supports slash-separated (`/`) names for packages and dollar-separated (`$`) inner classes.
public class AndroidClassName: @unchecked Sendable, ExpressibleByStringLiteral {
    /// Parent class or package (can be nil for root)
    public let parent: AndroidClassName?

    /// Current class segment (e.g. `"Build"` or `"LinearLayout"`)
    public let name: String

    /// Whether this component is an inner class (`$`) or nested under package (`/`)
    public let isInnerClass: Bool

    /// Full JNI-compatible class path (e.g. `"android/os/Build$VERSION"`)
    public let path: String

    /// Initialize from a root name (e.g. `"java"`, `"android"`)
    required public init(stringLiteral: String) {
        self.parent = nil
        self.name = stringLiteral
        self.isInnerClass = false
        self.path = name
    }

    /// Initialize from a parent and class segment, specifying whether it's an inner class.
    public init(parent: AndroidClassName, name: String, isInnerClass: Bool = false) {
        self.parent = parent
        self.name = name
        self.isInnerClass = isInnerClass
        let separator = isInnerClass ? "$" : "/"
        self.path = parent.path + separator + name
    }
}

extension AndroidClassName: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    public static func == (lhs: AndroidClassName, rhs: AndroidClassName) -> Bool {
        return lhs.path == rhs.path
    }
}