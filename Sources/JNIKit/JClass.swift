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
    public static func load(_ name: JClassName, _ classLoader: JClassLoader? = nil, asArray: Bool = false) -> JClass? {
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

    // MARK: - New Object

    /// Call to a constructor method which returns a new object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - args: An array of tuples containing the argument value and its corresponding JNI signature item.
    /// ```swift
    ///     args: [("string".wrap()!.object, .object("java/lang/String")), (0, .int)]
    /// ```
    ///  - Returns: The instance of constructed `JObject`.
    public func newObject(_ env: JEnv? = nil, args: [(any JValuable, JSignatureItem)]) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = methodId(env: env, name: "<init>", signature: .init(args.map({ $0.1 }), returning:.void))
        else { return nil }
        return env.newObject(clazz: self, constructor: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call to a constructor method which returns a new object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the method arguments.
    /// ```swift
    ///     args: ["hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0]
    /// ```
    ///  - Returns: The instance of constructed `JObject`.
    public func newObject(_ env: JEnv? = nil, args: [JSignatureItemable]) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = methodId(env: env, name: "<init>", signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning:.void))
        else { return nil }
        return env.newObject(clazz: self, constructor: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call to a constructor method which returns a new object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the constructor arguments.
    /// ```swift
    ///     args: "hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0
    /// ```
    ///  - Returns: The instance of constructed `JObject`.
    public func newObject(_ env: JEnv? = nil, args: JSignatureItemable...) -> JObject? {
        newObject(env, args: args)
    }

    // MARK: - Static Methods

    /// Call a static class method which returns an object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of tuples containing the argument value and its corresponding JNI signature item.
    /// ```swift
    ///     args: [("string".wrap()!.object, .object("java/lang/String")), (0, .int)]
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func staticObjectMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)], returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .object(returningSignatureClass ?? returningClass.name)))
        else { return nil }
        return env.callStaticObjectMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }), returningClass: returningClass)
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns an object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the method arguments.
    /// ```swift
    ///     args: ["hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0]
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func staticObjectMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable], returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .object(returningSignatureClass ?? returningClass.name)))
        else { return nil }
        return env.callStaticObjectMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }), returningClass: returningClass)
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns an object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the method arguments.
    /// ```swift
    ///     args: "hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func staticObjectMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable..., returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        staticObjectMethod(env, name: name, args: args, returningClass: returningClass, returningSignatureClass: returningSignatureClass)
    }

    /// Call a static class method which returns `jboolean`.
    public func staticBoolMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Bool? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .boolean))
        else { return nil }
        return env.callStaticBooleanMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jboolean`.
    public func staticBoolMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Bool? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .boolean))
        else { return nil }
        return env.callStaticBooleanMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jboolean`.
    public func staticBoolMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Bool? {
        staticBoolMethod(env, name: name, args: args)
    }

    /// Call a static class method which returns `jbyte`
    public func staticByteMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int8? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .byte))
        else { return nil }
        return env.callStaticByteMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jbyte`
    public func staticByteMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int8? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .byte))
        else { return nil }
        return env.callStaticByteMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jbyte`
    public func staticByteMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int8? {
        staticByteMethod(env, name: name, args: args)
    }

    /// Call a static class method which returns `jchar`
    public func staticCharMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> UInt16? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .char))
        else { return nil }
        return env.callStaticCharMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jchar`
    public func staticCharMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> UInt16? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .char))
        else { return nil }
        return env.callStaticCharMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jchar`
    public func staticCharMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> UInt16? {
        staticCharMethod(env, name: name, args: args)
    }

    /// Call a static class method which returns `jdouble`
    public func staticDoubleMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Double? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .double))
        else { return nil }
        return env.callStaticDoubleMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jdouble`
    public func staticDoubleMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Double? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .double))
        else { return nil }
        return env.callStaticDoubleMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jdouble`
    public func staticDoubleMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Double? {
        staticDoubleMethod(env, name: name, args: args)
    }

    /// Call a static class method which returns `jfloat`
    public func staticFloatMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Float? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .float))
        else { return nil }
        return env.callStaticFloatMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jfloat`
    public func staticFloatMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Float? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .float))
        else { return nil }
        return env.callStaticFloatMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jfloat`
    public func staticFloatMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Float? {
        staticFloatMethod(env, name: name, args: args)
    }
    
    /// Call a static class method which returns `jint`
    public func staticIntMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int32? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .int))
        else { return nil }
        return env.callStaticIntMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jint`
    public func staticIntMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int32? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .int))
        else { return nil }
        return env.callStaticIntMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `jint`
    public func staticIntMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int32? {
        staticIntMethod(env, name: name, args: args)
    }

    /// Call a static class method which returns `long`
    public func staticLongMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int64? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .long))
        else { return nil }
        return env.callStaticLongMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `long`
    public func staticLongMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int64? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .long))
        else { return nil }
        return env.callStaticLongMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call a static class method which returns `long`
    public func staticLongMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int64? {
        staticLongMethod(env, name: name, args: args)
    }

    /// Call a static class method which returns `void`
    public func staticVoidMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.1 }), returning: .void))
        else { return }
        env.callStaticVoidMethod(clazz: self, methodId: methodId, args: args.map({ $0.0 }))
        #endif
    }

    /// Call a static class method which returns `void`
    public func staticVoidMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = staticMethodId(name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .void))
        else { return }
        env.callStaticVoidMethod(clazz: self, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #endif
    }

    /// Call a static class method which returns `void`
    public func staticVoidMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) {
        staticVoidMethod(env, name: name, args: args)
    }

    // MARK: - Static Fields

    /// Get the value of a static field returning an object.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    ///   - signature: Field signature (e.g. `java/lang/String`)
    ///   - returningClass: The expected class of the returned object.
    /// - Returns: A wrapped `JObject` if the value is not null, or `nil`.
    public func staticObjectField(_ env: JEnv? = nil, name: String, returningClass: JClass) -> JObject? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\(signature.path)\""
        Logger.trace("JClass.objectField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .object(returningClass.name))
        else {
            #if JNILOGS
            Logger.debug("JClass.objectField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.objectField 2, got \(logKey)")
        #endif
        return env.getStaticObjectField(self, id, clazz: returningClass)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `boolean`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticBooleanField(_ env: JEnv? = nil, name: String) -> Bool? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.booleanField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .boolean)
        else {
            #if JNILOGS
            Logger.debug("JClass.booleanField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.booleanField 2, got \(logKey)")
        #endif
        return env.getStaticBooleanField(self, id)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `byte`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticByteField(_ env: JEnv? = nil, name: String) -> Int8? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.byteField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .byte)
        else {
            #if JNILOGS
            Logger.debug("JClass.byteField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.byteField 2, got \(logKey)")
        #endif
        return env.getStaticByteField(self, id)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `char`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticCharField(_ env: JEnv? = nil, name: String) -> UInt16? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.charField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .char)
        else {
            #if JNILOGS
            Logger.debug("JClass.charField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.charField 2, got \(logKey)")
        #endif
        return env.getStaticCharField(self, id)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `short`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticShortField(_ env: JEnv? = nil, name: String) -> Int16? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.shortField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .short)
        else {
            #if JNILOGS
            Logger.debug("JClass.shortField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.shortField 2, got \(logKey)")
        #endif
        return env.getStaticShortField(self, id)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `int`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticIntField(_ env: JEnv? = nil, name: String) -> Int32? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.intField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .int)
        else {
            #if JNILOGS
            Logger.debug("JClass.intField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.intField 2, got \(logKey)")
        #endif
        return env.getStaticIntField(self, id)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `long`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticLongField(_ env: JEnv? = nil, name: String) -> Int64? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.longField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .long)
        else {
            #if JNILOGS
            Logger.debug("JClass.longField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.longField 2, got \(logKey)")
        #endif
        return env.getStaticLongField(self, id)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `float`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticFloatField(_ env: JEnv? = nil, name: String) -> Float? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.floatField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .float)
        else {
            #if JNILOGS
            Logger.debug("JClass.floatField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.floatField 2, got \(logKey)")
        #endif
        return env.getStaticFloatField(self, id)
        #else
        return nil
        #endif
    }

    /// Get the value of a static field returning a `double`.
    ///
    /// - Parameters:
    ///   - env: Optional JNI environment. If `nil`, the current thread's environment will be used.
    ///   - name: Field name
    public func staticDoubleField(_ env: JEnv? = nil, name: String) -> Double? {
        #if os(Android)
        #if JNILOGS
        let logKey = "\"\(name)\""
        Logger.trace("JClass.doubleField 1, getting \(logKey)")
        #endif
        guard
            let env = env ?? JEnv.current(),
            let id = staticFieldId(name: name, signature: .double)
        else {
            #if JNILOGS
            Logger.debug("JClass.doubleField 1.1 exit: 💣 \(logKey) not found")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.trace("JClass.doubleField 2, got \(logKey)")
        #endif
        return env.getStaticDoubleField(self, id)
        #else
        return nil
        #endif
    }
}