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
public actor JNICache {
    /// Shared singleton instance for global access.
    public static let shared = JNICache()

    /// Cache for global `jclass` references by class name.
    private var classCache: [JClassName: JClass] = [:]

    /// Cache for instance and static method IDs by class and signature key.
    private var methodCache: [JClassName: [String: JMethodId]] = [:]

    /// Cache for instance and static field IDs by class and signature key.
    private var fieldCache: [JClassName: [String: JFieldId]] = [:]

    /// Pointer to the `JavaVM`, set once during initialization.
    private var javaVM: UnsafeMutablePointer<JavaVM?>?

    /// Store the global `JavaVM` pointer. Should be set once on startup.
    /// - Parameter jvm: The pointer to the active Java Virtual Machine
    public func setJavaVM(_ jvm: UnsafeMutablePointer<JavaVM?>) {
        self.javaVM = jvm
    }

    /// Attach the current thread to the JVM and retrieve the corresponding `JNIEnv*`.
    ///
    /// - Returns: A valid `JNIEnv*` for the current thread, or `nil` if attach fails.
    private func getEnv() -> UnsafeMutablePointer<JNIEnv?>? {
        guard let javaVM else { return nil }
        var env: UnsafeMutablePointer<JNIEnv?>?
        _ = javaVM.pointee?.pointee.AttachCurrentThread?(javaVM, &env, nil)
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
        if let cached = classCache[name] {
            return cached
        }
        guard
            let env = getEnv(),
            let local = env.pointee?.pointee.FindClass?(env, name.path),
            let global = env.pointee?.pointee.NewGlobalRef?(env, local)
        else { return nil }
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
        guard
            let clazz = getClass(className),
            let env = getEnv()
        else { return nil }
        let key = "\(methodName)\(signature.signature)"
        if let cached = methodCache[className]?[key] {
            return cached
        }
        let result = methodName.withCString { cname in
            signature.signature.withCString { csig in
                env.pointee?.pointee.GetMethodID?(env, clazz.ref, cname, csig)
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
                env.pointee?.pointee.GetStaticMethodID?(env, clazz.ref, cname, csig)
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
                env.pointee?.pointee.GetFieldID?(env, clazz.ref, fname, fsig)
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
                env.pointee?.pointee.GetStaticFieldID?(env, clazz.ref, fname, fsig)
            }
        }
        guard let fieldId = result else { return nil }
        let wrapper = JFieldId(fieldId)
        fieldCache[className, default: [:]][key] = wrapper
        return wrapper
    }
}