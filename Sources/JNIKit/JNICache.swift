//
//  JNICache.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android
#else
#if canImport(Glibc)
import Glibc
#endif
#endif
import Logging

/// A global actor responsible for caching JNI references and providing thread-safe access to `JNIEnv*`.
///
/// `JNICache` minimizes repeated lookups for classes, methods, and fields by caching global references.
/// It also automatically attaches the current thread to the JVM if needed.
public final class JNICache: @unchecked Sendable {
    /// Shared singleton instance for global access.
    public static let shared = JNICache()

    /// Cache for global `jclass` references by class name.
    private var classCache: [JClassName: JClass] = [:]

    /// Cache for instance and static method IDs by class and signature key.
    private var methodCache: [JClassName: [String: JMethodId]] = [:]

    /// Cache for instance and static field IDs by class and signature key.
    private var fieldCache: [JClassName: [String: JFieldId]] = [:]

    private var classMutex = pthread_mutex_t()
    private var methodMutex = pthread_mutex_t()
    private var fieldMutex = pthread_mutex_t()

    /// Private initializer to enforce singleton usage.
    private init() {
        classMutex.activate(recursive: true)
        methodMutex.activate(recursive: true)
        fieldMutex.activate(recursive: true)
    }

    deinit {
        classMutex.destroy()
        methodMutex.destroy()
        fieldMutex.destroy()
    }

    /// Attach the current thread to the JVM and retrieve the corresponding `JNIEnv*`.
    ///
    /// - Returns: A valid `JNIEnv*` for the current thread, or `nil` if attach fails.
    private func getEnv() -> JEnv? {
        guard let env = JNIKit.shared.vm.attachCurrentThread()
        else {
            #if DEBUG
            Logger.debug("💣 getEnv failed")
            #endif
            return nil
        }
        return env
    }

    /// Get a global, cached reference to the specified Java class.
    ///
    /// This method ensures the class is only looked up once via `FindClass`,
    /// converted into a global reference using `NewGlobalRef`, and cached for reuse.
    ///
    /// - Parameter name: The JNI class name (e.g. `"java/lang/String"`), using slash-separated format.
    /// - Returns: A `JClass` containing a globally retained `jclass` reference,
    ///            or `nil` if the class could not be found.
    public func getClass(_ name: JClassName) -> JClass? {
        #if os(Android)
        #if DEBUG
        let logKey = "\"\(name.fullName)\""
        Logger.trace("Getting class \(logKey) from cache")
        #endif
        classMutex.lock()
        defer { classMutex.unlock() }
        if let cached = classCache[name] {
            #if DEBUG
            Logger.trace("Got class \(logKey) from cache")
            #endif
            return cached
        }
        #if DEBUG
        Logger.trace("Class \(logKey) is not in cache")
        Logger.trace("Getting class \(logKey) from JNIEnv")
        #endif
        guard
            let env = getEnv(),
            let local = env.findClass(name),
            let global = env.newGlobalRef(local.ref)
        else {
            #if DEBUG
            Logger.debug("💣 Failed to get class \(logKey) from JNIEnv")
            #endif
            return nil
        }
        let wrapped = JClass(global, name)
        classCache[name] = wrapped
        #if DEBUG
        Logger.trace("Got class \(logKey) from JNIEnv, saved in cache")
        #endif
        return wrapped
        #else
        return nil
        #endif
    }

    /// Get an instance method ID for the specified class, method, and signature.
    ///
    /// - Parameters:
    ///   - className: The name of the class (e.g., `"java/lang/String"`)
    ///   - methodName: The method name (e.g., `"toString"`)
    ///   - signature: JNI signature string (e.g., `"()Ljava/lang/String;"`)
    /// - Returns: Cached or resolved `jmethodID`, or `nil` if not found.
    public func getMethodId(className: JClassName, methodName: String, signature: JMethodSignature) -> JMethodId? {
        #if os(Android)
        #if DEBUG
        let logKey = "\"\(className.fullName).\(methodName)\(signature.signature)\""
        Logger.trace("Getting methodId \(logKey) from cache")
        #endif
        methodMutex.lock()
        defer { methodMutex.unlock() }
        let key = "\(methodName)\(signature.signature)"
        if let cached = methodCache[className]?[key] {
            #if DEBUG
            Logger.trace("Got methodId \(logKey) from cache")
            #endif
            return cached
        }
        #if DEBUG
        Logger.trace("MethodId \(logKey) is not in cache")
        Logger.trace("Getting methodId \(logKey) from JNIEnv")
        #endif
        guard
            let env = getEnv(),
            let clazz = getClass(className)
        else { return nil }
        let result = methodName.withCString { cname in
            signature.signature.withCString { csig in
                env.env.pointee?.pointee.GetMethodID?(env.env, clazz.ref, cname, csig)
            }
        }
        guard let methodId = result else {
            #if DEBUG
            Logger.debug("💣 Failed to get methodId \(logKey) from JNIEnv")
            #endif
            return nil
        }
        let wrapper = JMethodId(methodId)
        methodCache[className, default: [:]][key] = wrapper
        #if DEBUG
        Logger.trace("Got methodId \(logKey) from JNIEnv, saved in cache")
        #endif
        return wrapper
        #else
        return nil
        #endif
    }

    /// Get a static method ID for the specified class, method, and signature.
    ///
    /// - Parameters:
    ///   - className: The name of the class (e.g., `"java/lang/System"`)
    ///   - methodName: The static method name (e.g., `"currentTimeMillis"`)
    ///   - signature: JNI signature string (e.g., `"()J"`)
    /// - Returns: Cached or resolved `jmethodID`, or `nil` if not found.
    public func getStaticMethodId(className: JClassName, methodName: String, signature: JMethodSignature) -> JMethodId? {
        #if os(Android)
        #if DEBUG
        let logKey = "\"\(className.fullName).\(methodName)\(signature.signature)\""
        Logger.trace("Getting staticMethodId \(logKey) from cache")
        #endif
        methodMutex.lock()
        defer { methodMutex.unlock() }
        let key = "static:\(methodName)\(signature.signature)"
        if let cached = methodCache[className]?[key] {
            #if DEBUG
            Logger.trace("Got staticMethodId \(logKey) from cache")
            #endif
            return cached
        }
        #if DEBUG
        Logger.trace("StaticMethodId \(logKey) is not in cache")
        Logger.trace("Getting staticMethodId \(logKey) from JNIEnv")
        #endif
        guard
            let clazz = getClass(className),
            let env = getEnv()
        else { return nil }
        let result = methodName.withCString { cname in
            signature.signature.withCString { csig in
                env.env.pointee?.pointee.GetStaticMethodID?(env.env, clazz.ref, cname, csig)
            }
        }
        guard let methodId = result else {
            #if DEBUG
            Logger.debug("💣 Failed to get staticMethodId \(logKey) from JNIEnv")
            #endif
            return nil
        }
        let wrapper = JMethodId(methodId)
        methodCache[className, default: [:]][key] = wrapper
        #if DEBUG
        Logger.trace("Got staticMethodId \(logKey) from JNIEnv, saved in cache")
        #endif
        return wrapper
        #else
        return nil
        #endif
    }

    /// Get an instance field ID for the specified class, field name, and signature.
    ///
    /// - Parameters:
    ///   - className: The class name (e.g., `"android/content/Intent"`)
    ///   - fieldName: The field name (e.g., `"mFlags"`)
    ///   - signature: JNI signature string (e.g., `"I"`)
    /// - Returns: Cached or resolved `jfieldID`, or `nil` if not found.
    public func getFieldId(className: JClassName, fieldName: String, signature: JSignatureItem) -> JFieldId? {
        #if os(Android)
        #if DEBUG
        let logKey = "\"\(className.fullName) \(fieldName)\(signature.signature)\""
        Logger.trace("Getting fieldId \(logKey) from cache")
        #endif
        fieldMutex.lock()
        defer { fieldMutex.unlock() }
        let key = "\(fieldName)\(signature.signature)"
        if let cached = fieldCache[className]?[key] {
            #if DEBUG
            Logger.trace("Got fieldId \(logKey) from cache")
            #endif
            return cached
        }
        #if DEBUG
        Logger.trace("FieldId \(logKey) is not in cache")
        Logger.trace("Getting fieldId \(logKey) from JNIEnv")
        #endif
        guard
            let clazz = getClass(className),
            let env = getEnv()
        else { return nil }
        let result = fieldName.withCString { fname in
            signature.signature.withCString { fsig in
                env.env.pointee?.pointee.GetFieldID?(env.env, clazz.ref, fname, fsig)
            }
        }
        guard let fieldId = result else {
            #if DEBUG
            Logger.debug("💣 Failed to get fieldId \(logKey) from JNIEnv")
            #endif
            return nil
        }
        let wrapper = JFieldId(fieldId)
        fieldCache[className, default: [:]][key] = wrapper
        #if DEBUG
        Logger.trace("Got fieldId \(logKey) from JNIEnv, saved in cache")
        #endif
        return wrapper
        #else
        return nil
        #endif
    }

    /// Get a static field ID for the specified class, field name, and signature.
    ///
    /// - Parameters:
    ///   - className: The class name (e.g., `"android/os/Build"`)
    ///   - fieldName: The static field name (e.g., `"MODEL"`)
    ///   - signature: JNI signature string (e.g., `"Ljava/lang/String;"`)
    /// - Returns: Cached or resolved `jfieldID`, or `nil` if not found.
    public func getStaticFieldId(className: JClassName, fieldName: String, signature: JSignatureItem) -> JFieldId? {
        #if os(Android)
        #if DEBUG
        let logKey = "\"\(className.fullName) \(fieldName)\(signature.signature)\""
        Logger.trace("Getting staticFieldId \(logKey) from cache")
        #endif
        fieldMutex.lock()
        defer { fieldMutex.unlock() }
        let key = "static:\(fieldName)\(signature.signature)"
        if let cached = fieldCache[className]?[key] {
            #if DEBUG
            Logger.trace("Got staticFieldId \(logKey) from cache")
            #endif
            return cached
        }
        #if DEBUG
        Logger.trace("StaticFieldId \(logKey) is not in cache")
        Logger.trace("Getting staticFieldId \(logKey) from JNIEnv")
        #endif
        guard
            let clazz = getClass(className),
            let env = getEnv()
        else { return nil }
        let result = fieldName.withCString { fname in
            signature.signature.withCString { fsig in
                env.env.pointee?.pointee.GetStaticFieldID?(env.env, clazz.ref, fname, fsig)
            }
        }
        guard let fieldId = result else {
            #if DEBUG
            Logger.debug("💣 Failed to get staticFieldId \(logKey) from JNIEnv")
            #endif
            return nil
        }
        let wrapper = JFieldId(fieldId)
        fieldCache[className, default: [:]][key] = wrapper
        #if DEBUG
        Logger.trace("Got staticFieldId \(logKey) from JNIEnv, saved in cache")
        #endif
        return wrapper
        #else
        return nil
        #endif
    }
}