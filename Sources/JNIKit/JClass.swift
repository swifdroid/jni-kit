//
//  JClass.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

import Android
import Logging

/// A type-safe wrapper around a globally retained Java class reference (`jclass`).
///
/// This wrapper ensures that:
/// - The class reference is global (not subject to local reference GC)
/// - It is looked up and retained only once via `JNICache`
/// - It is safe to use across Swift concurrency domains
///
/// Use this type to access method and field IDs or instantiate objects via JNI.
///
/// ### Example
/// ```swift
/// if let stringClass = JClass.load("java/lang/String") {
///     let toStringID = JNICache.shared.getMethodID(
///         className: stringClass.name,
///         methodName: "toString",
///         signature: "()Ljava/lang/String;"
///     )
/// }
/// ```
public struct JClass: @unchecked Sendable {
    /// A global JNI `jclass` reference.
    /// Safe to pass across threads but must be created via `NewGlobalRef`.
    public let ref: jclass

    /// Fully qualified JNI class name (e.g. `"java/lang/String"`).
    public let name: JClassName

    /// Construct manually from a global `jclass` and its name.
    /// Use only when you're sure the reference is global.
    public init(_ ref: jclass, _ name: JClassName) {
        self.ref = ref
        self.name = name
    }

    /// Convenient overload for optional `ref`
    public init?(_ ref: jclass?, _ name: JClassName) {
        guard let ref else { return nil }
        self.ref = ref
        self.name = name
    }

    /// Resolve and cache the Java class reference for the given name.
    ///
    /// This is the preferred way to construct a `JClass`.
    /// It automatically performs caching and returns a globally retained reference.
    ///
    /// - Parameter name: JNI class name using slashes (`/`) (e.g., `"java/lang/String"`).
    /// - Returns: A cached `JClass`, or `nil` if the class could not be loaded.
    public static func load(_ name: JClassName) -> JClass? {
        Logger.trace("Loading \"\(name.path)\" class")
        guard let result = JNICache.shared.getClass(name) else {
            Logger.debug("💣 Class \"\(name.path)\" not found")
            return nil
        }
        Logger.trace("Loaded \"\(name.path)\" class")
        return result
    }

    // MARK: - Instance Methods

    /// Get an instance method ID from this class.
    ///
    /// - Parameters:
    ///   - name: Method name (e.g. `"toString"`)
    ///   - signature: Method signature (e.g. `"()Ljava/lang/String;"`)
    /// - Returns: The method ID, or `nil` if not found.
    public func methodId(name: String, signature: JMethodSignature) -> JMethodId? {
        Logger.trace("Getting methodId \(name)\(signature.signature)")
        guard let id = JNICache.shared.getMethodId(className: self.name, methodName: name, signature: signature)
        else {
            Logger.debug("💣 MethodId \"\(name)\(signature.signature)\" not found")
            return nil
        }
        Logger.trace("Got methodId \(name)\(signature.signature)")
        return id
    }

    /// Get an instance field ID from this class.
    ///
    /// - Parameters:
    ///   - name: Field name (e.g. `"mFlags"`)
    ///   - signature: Field signature (e.g. `"I"`)
    /// - Returns: The field ID, or `nil` if not found.
    public func fieldId(name: String, signature: JSignatureItem) -> JFieldId? {
        Logger.trace("Getting fieldId \(name)\(signature.signature)")
        guard let id = JNICache.shared.getFieldId(className: self.name, fieldName: name, signature: signature)
        else {
            Logger.debug("💣 FieldId \"\(name)\(signature.signature)\" not found")
            return nil
        }
        Logger.trace("Got fieldId \(name)\(signature.signature)")
        return id
    }

    // MARK: - Static Methods

    /// Get a static method ID from this class.
    ///
    /// - Parameters:
    ///   - name: Static method name (e.g. `"currentTimeMillis"`)
    ///   - signature: Method signature (e.g. `"()J"`)
    /// - Returns: The static method ID, or `nil` if not found.
    public func staticMethodId(name: String, signature: JMethodSignature) -> JMethodId? {
        Logger.trace("Getting staticMethodId \(name)\(signature.signature)")
        guard let id = JNICache.shared.getStaticMethodId(className: self.name, methodName: name, signature: signature)
        else {
            Logger.debug("💣 StaticMethodId \"\(name)\(signature.signature)\" not found")
            return nil
        }
        Logger.trace("Got staticMethodId \(name)\(signature.signature)")
        return id
    }

    // MARK: - Static Fields

    /// Get a static field ID from this class.
    ///
    /// - Parameters:
    ///   - name: Field name (e.g. `"mFlags"`)
    ///   - signature: Field signature (e.g. `"I"`)
    /// - Returns: The static field ID, or `nil` if not found.
    public func staticFieldId(name: String, signature: JSignatureItem) -> JFieldId? {
        Logger.trace("Getting staticFieldId \(name)\(signature.signature)")
        guard let id = JNICache.shared.getStaticFieldId(className: self.name, fieldName: name, signature: signature)
        else {
            Logger.debug("💣 StaticFieldId \"\(name)\(signature.signature)\" not found")
            return nil
        }
        Logger.trace("Got staticFieldId \(name)\(signature.signature)")
        return id
    }
}