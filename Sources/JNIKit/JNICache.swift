//
//  JNICache.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

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
        let env = JNIKit.shared.vm.attachCurrentThread()
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
        classMutex.lock()
        defer { classMutex.unlock() }
        if let cached = classCache[name] {
            return cached
        }
        guard let env = getEnv()
        else {
            return nil
        }
        guard let local = env.findClass(name)
        else {
            return nil
        }
        guard let global = env.newGlobalRef(local.ref)
        else {
            return nil
        }
        let wrapped = JClass(global, name)
        classCache[name] = wrapped
        return wrapped
    }

    /// Get an instance method ID for the specified class, method, and signature.
    ///
    /// - Parameters:
    ///   - className: The name of the class (e.g., `"java/lang/String"`)
    ///   - methodName: The method name (e.g., `"toString"`)
    ///   - signature: JNI signature string (e.g., `"()Ljava/lang/String;"`)
    /// - Returns: Cached or resolved `jmethodID`, or `nil` if not found.
    public func getMethodId(className: JClassName, methodName: String, signature: JMethodSignature) -> JMethodId? {
        methodMutex.lock()
        defer { methodMutex.unlock() }
        guard let clazz = getClass(className) else {
            logger.info("getMethodId 2 exit")
            return nil
        }
        guard let env = getEnv() else {
            logger.info("getMethodId 3 exit")
            return nil
        }
        let key = "\(methodName)\(signature.signature)"
        if let cached = methodCache[className]?[key] {
            return cached
        }
        let result = methodName.withCString { cname in
            signature.signature.withCString { csig in
                env.env.pointee?.pointee.GetMethodID?(env.env, clazz.ref, cname, csig)
            }
        }
        guard let methodId = result else {
            return nil
        }
        let wrapper = JMethodId(methodId)
        methodCache[className, default: [:]][key] = wrapper
        return wrapper
    }

    /// Get a static method ID for the specified class, method, and signature.
    ///
    /// - Parameters:
    ///   - className: The name of the class (e.g., `"java/lang/System"`)
    ///   - methodName: The static method name (e.g., `"currentTimeMillis"`)
    ///   - signature: JNI signature string (e.g., `"()J"`)
    /// - Returns: Cached or resolved `jmethodID`, or `nil` if not found.
    public func getStaticMethodId(className: JClassName, methodName: String, signature: JMethodSignature) -> JMethodId? {
        methodMutex.lock()
        defer { methodMutex.unlock() }
        guard
            let clazz = getClass(className),
            let env = getEnv()
        else { return nil }
        let key = "static:\(methodName)\(signature.signature)"
        if let cached = methodCache[className]?[key] {
            return cached
        }
        let result = methodName.withCString { cname in
            signature.signature.withCString { csig in
                env.env.pointee?.pointee.GetStaticMethodID?(env.env, clazz.ref, cname, csig)
            }
        }
        guard let methodId = result else {
            return nil
        }
        let wrapper = JMethodId(methodId)
        methodCache[className, default: [:]][key] = wrapper 
        return wrapper
    }

    /// Get an instance field ID for the specified class, field name, and signature.
    ///
    /// - Parameters:
    ///   - className: The class name (e.g., `"android/content/Intent"`)
    ///   - fieldName: The field name (e.g., `"mFlags"`)
    ///   - signature: JNI signature string (e.g., `"I"`)
    /// - Returns: Cached or resolved `jfieldID`, or `nil` if not found.
    public func getFieldId(className: JClassName, fieldName: String, signature: JSignatureItem) -> JFieldId? {
        fieldMutex.lock()
        defer { fieldMutex.unlock() }
        guard
            let clazz = getClass(className),
            let env = getEnv()
        else { return nil }
        let key = "\(fieldName)\(signature.signature)"
        if let cached = fieldCache[className]?[key] {
            return cached
        }
        let result = fieldName.withCString { fname in
            signature.signature.withCString { fsig in
                env.env.pointee?.pointee.GetFieldID?(env.env, clazz.ref, fname, fsig)
            }
        }
        guard let fieldId = result else { return nil }
        let wrapper = JFieldId(fieldId)
        fieldCache[className, default: [:]][key] = wrapper
        return wrapper
    }

    /// Get a static field ID for the specified class, field name, and signature.
    ///
    /// - Parameters:
    ///   - className: The class name (e.g., `"android/os/Build"`)
    ///   - fieldName: The static field name (e.g., `"MODEL"`)
    ///   - signature: JNI signature string (e.g., `"Ljava/lang/String;"`)
    /// - Returns: Cached or resolved `jfieldID`, or `nil` if not found.
    public func getStaticFieldId(className: JClassName, fieldName: String, signature: JSignatureItem) -> JFieldId? {
        fieldMutex.lock()
        defer { fieldMutex.unlock() }
        guard
            let clazz = getClass(className),
            let env = getEnv()
        else { return nil }
        let key = "static:\(fieldName)\(signature.signature)"
        if let cached = fieldCache[className]?[key] {
            return cached
        }
        let result = fieldName.withCString { fname in
            signature.signature.withCString { fsig in
                env.env.pointee?.pointee.GetStaticFieldID?(env.env, clazz.ref, fname, fsig)
            }
        }
        guard let fieldId = result else { return nil }
        let wrapper = JFieldId(fieldId)
        fieldCache[className, default: [:]][key] = wrapper
        return wrapper
    }
}