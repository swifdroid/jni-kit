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
#if JNILOGS
#if canImport(Logging)
import Logging
#endif
#endif

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
            #if JNITRACE
            Logger.critical("💣 getEnv failed")
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
        #if JNILOGS
        let logKey = "\"\(name.fullName)\""
        Logger.trace("JNICache.getClass 1  className: \(logKey)")
        #endif
        classMutex.lock()
        defer { classMutex.unlock() }
        if let cached = classCache[name] {
            #if JNILOGS
            Logger.trace("JNICache.getClass 1 return cached: \(logKey)")
            #endif
            return cached
        }
        #if JNILOGS
        Logger.trace("JNICache.getClass 2 \(logKey) not in cache, calling JNI")
        #endif
        guard
            let env = getEnv()
        else {
            #if JNILOGS
            Logger.trace("JNICache.getClass 2 exit 1")
            #endif
            return nil
        }
        guard
            let global = env.findClass(name)
        else {
            #if JNILOGS
            Logger.trace("JNICache.getClass 2 exit 2")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JNICache.getClass 3")
        #endif
        classCache[name] = global
        #if JNILOGS
        Logger.trace("JNICache.getClass 4, got class \(logKey) from JNI, saved in cache")
        #endif
        return global
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
    public func getMethodId(env: JEnv, clazz: JClass, methodName: String, signature: JMethodSignature) -> JMethodId? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(clazz.name.fullName).\(methodName)\(signature.signature)\""
        Logger.trace("JNICache.getMethodId 1, getting \(logKey) from cache")
        #endif
        methodMutex.lock()
        defer { methodMutex.unlock() }
        let key = "\(methodName)\(signature.signature)"
        if let cached = methodCache[clazz.name]?[key] {
            #if JNILOGS
            Logger.trace("JNICache.getMethodId 2, got \(logKey) from cache")
            #endif
            return cached
        }
        #if JNILOGS
        Logger.trace("JNICache.getMethodId 3, \(logKey) is not in cache, getting from JNI")
        #endif
        let result = methodName.withCString { cname in
            signature.signature.withCString { csig in
                env.env.pointee?.pointee.GetMethodID?(env.env, clazz.ref, cname, csig)
            }
        }
        #if JNILOGS
        Logger.trace("JNICache.getMethodId 4")
        #endif
        guard let methodId = result else {
            #if JNILOGS
            Logger.debug("JNICache.getMethodId 4.1 exit: 💣 Failed to get \(logKey) from JNI")
            #endif
            return nil
        }
        let wrapper = JMethodId(methodId)
        methodCache[clazz.name, default: [:]][key] = wrapper
        #if JNILOGS
        Logger.trace("JNICache.getMethodId 5, got \(logKey) from JNIEnv, saved in cache")
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
        #if JNILOGS
        let logKey = "\"\(className.fullName).\(methodName)\(signature.signature)\""
        Logger.trace("JNICache.getStaticMethodId 1, getting \(logKey) from cache")
        #endif
        methodMutex.lock()
        defer { methodMutex.unlock() }
        let key = "static:\(methodName)\(signature.signature)"
        if let cached = methodCache[className]?[key] {
            #if JNILOGS
            Logger.trace("JNICache.getStaticMethodId 2, got \(logKey) from cache")
            #endif
            return cached
        }
        #if JNILOGS
        Logger.trace("JNICache.getStaticMethodId 3, \(logKey) is not in cache, getting from JNI")
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
        #if JNILOGS
        Logger.trace("JNICache.getStaticMethodId 4")
        #endif
        guard let methodId = result else {
            #if JNILOGS
            Logger.debug("JNICache.getStaticMethodId 4.1 exit: 💣 Failed to get \(logKey) from JNI")
            #endif
            return nil
        }
        let wrapper = JMethodId(methodId)
        methodCache[className, default: [:]][key] = wrapper
        #if JNILOGS
        Logger.trace("JNICache.getStaticMethodId 5, got \(logKey) from JNI, saved in cache")
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
        #if JNILOGS
        let logKey = "\"\(className.fullName) \(fieldName)\(signature.signature)\""
        Logger.trace("JNICache.getFieldId 1, getting \(logKey) from cache")
        #endif
        fieldMutex.lock()
        defer { fieldMutex.unlock() }
        let key = "\(fieldName)\(signature.signature)"
        if let cached = fieldCache[className]?[key] {
            #if JNILOGS
            Logger.trace("JNICache.getFieldId 2, got \(logKey) from cache")
            #endif
            return cached
        }
        #if JNILOGS
        Logger.trace("JNICache.getFieldId 3, \(logKey) is not in cache, getting from JNI")
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
        #if JNILOGS
        Logger.trace("JNICache.getFieldId 4")
        #endif
        guard let fieldId = result else {
            #if JNILOGS
            Logger.debug("JNICache.getFieldId 4.1 exit: 💣 Failed to get \(logKey) from JNI")
            #endif
            return nil
        }
        let wrapper = JFieldId(fieldId)
        fieldCache[className, default: [:]][key] = wrapper
        #if JNILOGS
        Logger.trace("JNICache.getFieldId 5, got \(logKey) from JNI, saved in cache")
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
        #if JNILOGS
        let logKey = "\"\(className.fullName) \(fieldName)\(signature.signature)\""
        Logger.trace("JNICache.getStaticFieldId 1, getting \(logKey) from cache")
        #endif
        fieldMutex.lock()
        defer { fieldMutex.unlock() }
        let key = "static:\(fieldName)\(signature.signature)"
        if let cached = fieldCache[className]?[key] {
            #if JNILOGS
            Logger.trace("JNICache.getStaticFieldId 2, got \(logKey) from cache")
            #endif
            return cached
        }
        #if JNILOGS
        Logger.trace("JNICache.getStaticFieldId 3, \(logKey) is not in cache, getting from JNI")
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
        #if JNILOGS
        Logger.trace("JNICache.getStaticFieldId 4")
        #endif
        guard let fieldId = result else {
            #if JNILOGS
            Logger.debug("JNICache.getStaticFieldId 4.1 exit: 💣 Failed to get \(logKey) from JNI")
            #endif
            return nil
        }
        let wrapper = JFieldId(fieldId)
        fieldCache[className, default: [:]][key] = wrapper
        #if JNILOGS
        Logger.trace("JNICache.getStaticFieldId 5, got \(logKey) from JNI, saved in cache")
        #endif
        return wrapper
        #else
        return nil
        #endif
    }
}