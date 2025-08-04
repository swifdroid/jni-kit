//
//  JClass.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if os(Android)
import Android
#endif
#if JNILOGS
#if canImport(Logging)
import Logging
#endif
#endif

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
public class JClass: @unchecked Sendable {
    #if os(Android)
    /// A global JNI `jclass` reference.
    /// Safe to pass across threads but must be created via `NewGlobalRef`.
    public let ref: jclass
    #endif

    /// Fully qualified JNI class name (e.g. `"java/lang/String"`).
    public let name: JClassName

    /// Is it has global reference or local
    public let isGlobalRef: Bool

    #if os(Android)
    /// Construct manually from a global `jclass` and its name.
    /// Use only when you're sure the reference is global.
    public init(_ ref: jclass, _ name: JClassName, isGlobalRef: Bool = true) {
        self.ref = ref
        self.name = name
        self.isGlobalRef = isGlobalRef
    }

    /// Convenient overload for optional `ref`
    public convenience init?(_ ref: jclass?, _ name: JClassName, isGlobalRef: Bool = true) {
        guard let ref else { return nil }
        self.init(ref, name, isGlobalRef: isGlobalRef)
    }
    #else
    public init(_ name: JClassName, isGlobalRef: Bool = true) {
        self.name = name
        self.isGlobalRef = isGlobalRef
    }
    #endif

    deinit {
        #if JNILOGS
        Logger.critical("🧹🧹🧹 deleted \(isGlobalRef ? "global" : "local") ref: \(ref)")
        #endif
        #if os(Android)
        if isGlobalRef {
            JEnv.current()?.deleteGlobalRef(ref)
        } else {
            JEnv.current()?.deleteLocalRef(ref)
        }
        #endif
    }

    /// Resolve and cache the Java class reference for the given name.
    ///
    /// This is the preferred way to construct a `JClass`.
    /// It automatically performs caching and returns a globally retained reference.
    ///
    /// - Parameters:
    ///   - name: JNI class name using slashes (`/`) (e.g., `"java/lang/String"`).
    ///   - classLoader: optional object confirming to JClassLoader, but necessary for non-system classes
    /// - Returns: A cached `JClass`, or `nil` if the class could not be loaded.
    public static func load(_ name: JClassName, _ classLoader: JClassLoader? = nil) -> JClass? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name.path)\""
        Logger.trace("JClass.load 1, loading \(logKey)")
        #endif
        guard let result = JNICache.shared.getClass(name, classLoader) else {
            #if JNILOGS
            Logger.debug("JClass.load 1.1 exit: 💣 Class \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.load 2, loaded \(logKey)")
        #endif
        return result
        #else
        return nil
        #endif
    }

    // MARK: - Instance Methods

    /// Get an instance method ID from this class.
    ///
    /// - Parameters:
    ///   - name: Method name (e.g. `"toString"`)
    ///   - signature: Method signature (e.g. `"()Ljava/lang/String;"`)
    /// - Returns: The method ID, or `nil` if not found.
    public func methodId(env: JEnv, name: String, signature: JMethodSignature) -> JMethodId? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\(signature.signature)\""
        Logger.trace("JClass.methodId 1, getting \(logKey)")
        #endif
        guard let id = JNICache.shared.getMethodId(env: env, clazz: self, methodName: name, signature: signature)
        else {
            #if JNILOGS
            Logger.debug("JClass.methodId 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.methodId 2, got \(logKey)")
        #endif
        return id
        #else
        return nil
        #endif
    }

    /// Get an instance field ID from this class.
    ///
    /// - Parameters:
    ///   - name: Field name (e.g. `"mFlags"`)
    ///   - signature: Field signature (e.g. `"I"`)
    /// - Returns: The field ID, or `nil` if not found.
    public func fieldId(name: String, signature: JSignatureItem) -> JFieldId? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\(signature.signature)\""
        Logger.trace("JClass.fieldId 1, getting \(logKey)")
        #endif
        guard let id = JNICache.shared.getFieldId(clazz: self, fieldName: name, signature: signature)
        else {
            #if JNILOGS
            Logger.debug("JClass.fieldId 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.fieldId 2, got \(logKey)")
        #endif
        return id
        #else
        return nil
        #endif
    }

    // MARK: - Static Methods

    /// Get a static method ID from this class.
    ///
    /// - Parameters:
    ///   - name: Static method name (e.g. `"currentTimeMillis"`)
    ///   - signature: Method signature (e.g. `"()J"`)
    /// - Returns: The static method ID, or `nil` if not found.
    public func staticMethodId(name: String, signature: JMethodSignature) -> JMethodId? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\(signature.signature)\""
        Logger.trace("JClass.staticMethodId 1, getting \(logKey)")
        #endif
        guard let id = JNICache.shared.getStaticMethodId(clazz: self, methodName: name, signature: signature)
        else {
            #if JNILOGS
            Logger.debug("JClass.staticMethodId 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.staticMethodId 2, got \(logKey)")
        #endif
        return id
        #else
        return nil
        #endif
    }

    // MARK: - Static Fields

    /// Get a static field ID from this class.
    ///
    /// - Parameters:
    ///   - name: Field name (e.g. `"mFlags"`)
    ///   - signature: Field signature (e.g. `"I"`)
    /// - Returns: The static field ID, or `nil` if not found.
    public func staticFieldId(name: String, signature: JSignatureItem) -> JFieldId? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\(signature.signature)\""
        Logger.trace("JClass.staticFieldId 1, getting \(logKey)")
        #endif
        guard let id = JNICache.shared.getStaticFieldId(clazz: self, fieldName: name, signature: signature)
        else {
            #if JNILOGS
            Logger.debug("JClass.staticFieldId 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.staticFieldId 2, got \(logKey)")
        #endif
        return id
        #else
        return nil
        #endif
    }
}