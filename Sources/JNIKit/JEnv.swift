//
//  JEnv.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if os(Android)
import Android
#endif

/// A thread-safe, ergonomic Swift wrapper around `JNIEnv*` for use with JNI in Swift 6.1+.
///
/// `JEnv` provides structured, concurrency-aware access to the JNI environment.
/// It wraps the thread-local `JNIEnv*`, allowing you to interact with Java from Swift
/// without directly using unsafe C pointers.
///
/// ⚠️ Always retrieve a `JEnv` using `JVM.attachCurrentThread()` or `JEnv.current()`
/// to ensure you're on a thread properly attached to the JVM.
///
/// Example:
/// ```swift
/// if let env = JEnv.current() {
///     let stringClass = try env.findClass("java/lang/String")
///     ...
/// }
/// ```
public struct JEnv: @unchecked Sendable {
    #if os(Android)
    /// The raw JNI environment pointer for the current thread (`JNIEnv*`).
    ///
    /// This pointer is thread-local and should only be used from the thread
    /// it was obtained on. It must be accessed through safe abstractions like `JEnv`.
    public let env: UnsafeMutablePointer<JNIEnv?>

    // MARK: - Initializers

    /// Create a `JEnv` from a non-optional `JNIEnv*`.
    ///
    /// Use this only if you're absolutely certain the environment pointer is valid.
    /// For safety in most cases, prefer the optional variant or `JEnv.current()`.
    ///
    /// - Parameter env: A raw, non-optional pointer to `JNIEnv`.
    public init(_ env: UnsafeMutablePointer<JNIEnv?>) {
        self.env = env
    }

    /// Create a `JEnv` from an optional `JNIEnv*`, returning `nil` if the pointer is null.
    ///
    /// - Parameter env: An optional JNI environment pointer.
    public init?(_ env: UnsafeMutablePointer<JNIEnv?>?) {
        guard let env else { return nil }
        self.env = env
    }
    #endif
}

extension JEnv {
    /// Returns the current thread’s `JNIEnv` by attaching (or reusing) the thread to the JVM.
    ///
    /// This is the **recommended way** to access `JNIEnv*` from Swift, as it:
    /// - Ensures the current thread is attached to the JVM (if not already)
    /// - Retrieves the appropriate `JNIEnv*` for the calling thread
    /// - Returns a safe, concurrency-compatible `JEnv` wrapper
    ///
    /// This method requires that `JNIKit.shared.vm` is already initialized with the `JavaVM*`
    /// (typically set during JNI_OnLoad or first entry into native Swift).
    ///
    /// Example usage:
    /// ```swift
    /// if let env = JEnv.current() {
    ///     let clazz = env.findClass("java/lang/String")
    ///     ...
    /// }
    /// ```
    ///
    /// - Returns: A `JEnv` instance for the current thread, or `nil` if the JVM is not yet available.
    public static func current() -> JEnv? {
        JNIKit.shared.vm.attachCurrentThread()
    }
}

/// Represents a parsed JNI version, like 1.8 or 1.6.
public struct JNIVersion: Equatable, Hashable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int

    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }

    /// A string representation like "1.8"
    public var description: String {
        "\(major).\(minor)"
    }
}

#if os(Android)
extension JEnv {
    // MARK: - Version

    /// Returns the version of the JNI environment provided by the JVM.
    ///
    /// This is typically used to verify compatibility (e.g. `0x00010008` = JNI 1.8).
    public func getVersion() -> Int32 {
        env.pointee!.pointee.GetVersion(env)
    }

    /// Returns the JNI version parsed into a `JNIVersion` struct.
    public func getVersionStruct() -> JNIVersion {
        let raw = getVersion()
        let major = Int((raw >> 16) & 0xFFFF)
        let minor = Int(raw & 0xFFFF)
        return JNIVersion(major: major, minor: minor)
    }

    /// Returns the JNI version as a human-readable string (e.g. `"1.8"`).
    public func getVersionString() -> String {
        getVersionStruct().description
    }

    // MARK: - Class Definition

    /// Defines a new Java class dynamically from raw bytecode.
    ///
    /// - Parameters:
    ///   - name: The fully qualified class name (e.g., `"com/example/MyClass"`)
    ///   - loader: A class loader object (or `nil` for bootstrap loader)
    ///   - buf: Pointer to the `.class` bytecode
    ///   - size: Size of the bytecode buffer
    /// - Returns: A newly defined Java class, or `nil` if failed.
    public func defineClass(name: JClassName, loader: JObject?, buf: UnsafePointer<jbyte>, size: jint) -> JClass? {
        name.path.withCString {
            let local = env.pointee!.pointee.DefineClass!(env, $0, loader?.ref.ref, buf, size)
            defer {
                env.pointee!.pointee.DeleteLocalRef(env, local)
            }
            return JClass(env.pointee!.pointee.NewGlobalRef(env, local), name)
        }
    }

    /// Finds a class by name using the current class loader.
    ///
    /// - Parameter name: JNI slash-separated class path (e.g. `"java/lang/String"`)
    /// - Returns: A wrapped class reference or `nil` if not found.
    public func findClass(_ name: JClassName) -> JClass? {
        name.path.withCString {
            let local = env.pointee!.pointee.FindClass!(env, $0)
            defer {
                env.pointee!.pointee.DeleteLocalRef(env, local)
            }
            return JClass(env.pointee!.pointee.NewGlobalRef(env, local), name)
        }
    }

    // MARK: - Reflection Conversion

    /// Converts a Java `Method` object to a native method ID.
    public func fromReflectedMethod(_ method: JObject) -> JMethodId? {
        JMethodId(env.pointee!.pointee.FromReflectedMethod!(env, method.ref.ref))
    }

    /// Converts a Java `Field` object to a native field ID.
    public func fromReflectedField(_ field: JObject) -> JFieldId? {
        JFieldId(env.pointee!.pointee.FromReflectedField!(env, field.ref.ref))
    }

    /// Converts a native method ID into a Java `Method` or `Constructor` object.
    ///
    /// - Parameters:
    ///   - clazz: The class that declares the method
    ///   - methodId: The native method ID
    ///   - isStatic: Whether the method is static
    public func toReflectedMethod(clazz: JClass, methodId: JMethodId, isStatic: Bool) -> JObject? {
        guard
            let box = env.pointee!.pointee.ToReflectedMethod!(env, clazz.ref, methodId.id, isStatic.jboolean)?.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz)
    }

    /// Converts a native field ID into a Java `Field` object.
    ///
    /// - Parameters:
    ///   - clazz: The declaring class
    ///   - fieldId: Native field ID
    ///   - isStatic: Whether the field is static
    public func toReflectedField(clazz: JClass, fieldId: JFieldId, isStatic: Bool) -> JObject? {
        guard
            let box = env.pointee!.pointee.ToReflectedField!(env, clazz.ref, fieldId.id, isStatic.jboolean)?.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz)
    }

    // MARK: - Class Hierarchy

    /// Gets the superclass of a Java class.
    public func getSuperclass(of clazz: JClass) -> JClass? {
        let local = env.pointee!.pointee.GetSuperclass!(env, clazz.ref)
        defer {
            env.pointee!.pointee.DeleteLocalRef(env, local)
        }
        return JClass(env.pointee!.pointee.NewGlobalRef(env, local), clazz.name)
    }

    /// Determines if `clazz2` is assignable to `clazz1`, equivalent to `clazz1.isAssignableFrom(clazz2)` in Java.
    public func isAssignable(from clazz1: JClass, to clazz2: JClass) -> Bool {
        env.pointee!.pointee.IsAssignableFrom!(env, clazz1.ref, clazz2.ref).value
    }

    // MARK: - Exceptions

    /// Throws an existing exception object in the JVM.
    ///
    /// - Parameter throwable: A `jthrowable` object
    /// - Returns: JNI status (`0` = OK, `-1` = error)
    public func throwException(_ throwable: jthrowable) -> Int32 {
        env.pointee!.pointee.Throw!(env, throwable)
    }

    /// Throws a new exception given a class and error message.
    ///
    /// - Parameters:
    ///   - clazz: Exception class (e.g. `java/lang/IllegalArgumentException`)
    ///   - message: Error message
    /// - Returns: JNI status
    public func throwNew(clazz: JClass, message: String) -> Int32 {
        message.withCString {
            env.pointee!.pointee.ThrowNew!(env, clazz.ref, $0)
        }
    }

    /// Checks whether a Java exception has been thrown in the current thread.
    ///
    /// - Returns: A throwable object if an exception is pending, or `nil`.
    public func exceptionOccurred() -> JThrowable? {
        guard
            let throwable = env.pointee!.pointee.ExceptionOccurred!(env),
            let box = throwable.box(JEnv(env)),
            let clazz = JClass.load("java/lang/Throwable")
        else { return nil }
        return JThrowable(box, clazz)
    }

    /// Describes the current exception (if any) to stderr (for debugging).
    public func exceptionDescribe() {
        env.pointee!.pointee.ExceptionDescribe!(env)
    }

    /// Clears the current exception from the JVM (if one is pending).
    public func exceptionClear() {
        env.pointee!.pointee.ExceptionClear!(env)
    }

    /// Triggers a fatal error in the JVM with a custom message. This terminates the VM.
    public func fatalError(_ message: String) {
        message.withCString {
            env.pointee!.pointee.FatalError!(env, $0)
        }
    }

    /// Throws a Java exception object that is a subclass of `Throwable`.
    public func throwObject(_ throwable: jobject) -> Int32 {
        env.pointee!.pointee.Throw!(env, throwable)
    }

    /// Throws a `JThrowable` instance and returns a typed JNI status.
    public func throwObject(_ throwable: JThrowable) -> JNIStatus {
        JNIStatus(fromRawValue: env.pointee!.pointee.Throw!(env, throwable.ref.ref))
    }

    // MARK: - Reference Frames

    /// Pushes a new local reference frame, allowing scoped object reference tracking.
    ///
    /// - Parameter capacity: Number of local refs to allocate.
    /// - Returns: JNI status code
    public func pushLocalFrame(capacity: jint) -> Int32 {
        env.pointee!.pointee.PushLocalFrame!(env, capacity)
    }

    /// Pops the current local frame, returning a single retained reference.
    ///
    /// - Parameter result: Optional object to retain from the popped frame
    public func popLocalFrame(result: JObject?) -> JObject? {
        guard
            let box = env.pointee!.pointee.PopLocalFrame!(env, result?.ref.ref)?.box(JEnv(env))
        else { return nil }
        return JObject(box, result?.clazz)
    }

    // MARK: - Reference Management

    /// Promotes a local reference to a global one (GC-safe).
    public func newGlobalRef(_ obj: JObject) -> JObject? {
        guard
            let box = env.pointee!.pointee.NewGlobalRef!(env, obj.ref.ref)?.box(JEnv(env))
        else { return nil }
        return JObject(box, obj.clazz)
    }

    /// Promotes a local reference to a global one (GC-safe).
    public func newGlobalRef(_ ref: jobject) -> jobject? {
        env.pointee!.pointee.NewGlobalRef!(env, ref)
    }

    /// Deletes a global reference previously promoted.
    public func deleteGlobalRef(_ globalRef: JObject) {
        env.pointee!.pointee.DeleteGlobalRef!(env, globalRef.ref.ref)
    }

    /// Deletes a global reference previously promoted.
    public func deleteGlobalRef(_ globalRef: jobject) {
        env.pointee!.pointee.DeleteGlobalRef!(env, globalRef)
    }

    /// Deletes a local reference to allow early GC.
    public func deleteLocalRef(_ localRef: JObject) {
        env.pointee!.pointee.DeleteLocalRef!(env, localRef.ref.ref)
    }

    /// Deletes a local reference to allow early GC.
    public func deleteLocalRef(_ localRef: jobject) {
        env.pointee!.pointee.DeleteLocalRef!(env, localRef)
    }

    /// Returns whether two `jobject`s refer to the same underlying Java object.
    public func isSameObject(_ obj1: JObject, _ obj2: JObject) -> Bool {
        env.pointee!.pointee.IsSameObject!(env, obj1.ref.ref, obj2.ref.ref).value
    }

    /// Creates a new local reference to the given object.
    public func newLocalRef(_ obj: JObject) -> JObject? {
        guard
            let box = env.pointee!.pointee.NewLocalRef!(env, obj.ref.ref)?.box(JEnv(env))
        else { return nil }
        return JObject(box, obj.clazz)
    }

    /// Ensures there's room for `capacity` more local references in the current frame.
    ///
    /// - Returns: JNI status
    public func ensureLocalCapacity(_ capacity: jint) -> Int32 {
        env.pointee!.pointee.EnsureLocalCapacity!(env, capacity)
    }

    // MARK: - Object Allocation

    /// Allocates an instance of a class without calling its constructor.
    public func allocObject(_ clazz: JClass) -> JObject? {
        guard
            let box = env.pointee!.pointee.AllocObject!(env, clazz.ref)?.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz)
    }

    // MARK: - Object Creation

    /// Creates a new Java object by calling its constructor using a `jvalue[]` argument list.
    ///
    /// This is equivalent to:
    /// ```c
    /// jobject obj = (*env)->NewObjectA(env, clazz, constructor, args.map { $0.jValue });
    /// ```
    ///
    /// - Parameters:
    ///   - clazz: The class of the object to instantiate.
    ///   - constructor: A `JMethodId` representing the `<init>` constructor method.
    ///   - args: Pointer to an array of `jvalue` arguments for the constructor, or `nil` if none.
    /// - Returns: A new `JObject` instance or `nil` if object creation failed.
    public func newObject(
        clazz: JClass,
        constructor: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> JObject? {
        guard
            let obj = env.pointee!.pointee.NewObjectA!(env, clazz.ref, constructor.id, args?.map { $0.jValue }),
            let box = obj.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz)
    }

    // MARK: - Object Info

    /// Retrieves the class of a given Java object at runtime.
    ///
    /// This wraps the JNI call to `GetObjectClass`, which returns the object's concrete class.
    ///
    /// - Parameter object: The object to inspect.
    /// - Returns: A `JClass` representing the object's runtime class.
    // public func getObjectClass(_ object: jobject) -> JClass? {
    //     let local = env.pointee!.pointee.GetObjectClass!(env, object)
    //     defer {
    //         env.pointee!.pointee.DeleteLocalRef(env, local)
    //     }
    //     return JClass(env.pointee!.pointee.NewGlobalRef(env, local), object.className) // TODO: get class name. or decide that this situation is impossible in current architecture
    // }

    /// Checks whether a Java object is an instance of a given class.
    ///
    /// Equivalent to `clazz.isInstance(obj)` in Java.
    ///
    /// - Parameters:
    ///   - object: The Java object to check.
    ///   - clazz: The class to compare against.
    /// - Returns: `true` if `object` is an instance of `clazz` or its subclass; otherwise, `false`.
    public func isInstanceOf(_ object: JObject, _ clazz: JClass) -> Bool {
        env.pointee!.pointee.IsInstanceOf!(env, object.ref.ref, clazz.ref) == UInt8(JNI_TRUE)
    }

    // MARK: - Method Lookup

    /// Finds an instance method ID for a method declared in the given class.
    ///
    /// This wraps the JNI `GetMethodID` call and converts it into a `JMethodId`.
    ///
    /// - Parameters:
    ///   - clazz: The class in which the method is declared.
    ///   - name: The method name (e.g., `"toString"`).
    ///   - sig: The method signature (e.g., `"()Ljava/lang/String;"`).
    /// - Returns: A `JMethodId` if found, or `nil` if the method doesn't exist or lookup fails.
    public func getMethodId(
        clazz: JClass,
        name: String,
        sig: JMethodSignature
    ) -> JMethodId? {
        name.withCString { cname in
            sig.signature.withCString { csig in
                JMethodId(env.pointee!.pointee.GetMethodID!(env, clazz.ref, cname, csig))
            }
        }
    }

    // MARK: - Instance Method Calls

    /// Call a Java method returning an `Object`.
    public func callObjectMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
        clazz: JClass? = nil,
    ) -> JObject? {
        guard
            let box = env.pointee!.pointee.CallObjectMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })?.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz ?? object.clazz)
    }
    }

    /// Call a Java method returning `boolean`.
    public func callBooleanMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Bool {
        env.pointee!.pointee.CallBooleanMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue }).value
    }

    /// Call a Java method returning `byte`.
    public func callByteMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int8 {
        env.pointee!.pointee.CallByteMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a Java method returning `char`.
    public func callCharMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> UInt16 {
        env.pointee!.pointee.CallCharMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a Java method returning `short`.
    public func callShortMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int16 {
        env.pointee!.pointee.CallShortMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a Java method returning `int`.
    public func callIntMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int32 {
        env.pointee!.pointee.CallIntMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a Java method returning `long`.
    public func callLongMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int64 {
        env.pointee!.pointee.CallLongMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a Java method returning `float`.
    public func callFloatMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Float {
        env.pointee!.pointee.CallFloatMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a Java method returning `double`.
    public func callDoubleMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Double {
        env.pointee!.pointee.CallDoubleMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a Java method returning `void`.
    public func callVoidMethod(
        object: JObject,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) {
        env.pointee!.pointee.CallVoidMethodA!(env, object.ref.ref, methodId.id, args?.map { $0.jValue })
    }

    // MARK: - Non-Virtual Method Calls

    /// Call a nonvirtual Java method returning an `Object`.
    public func callNonvirtualObjectMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> JObject? {
        guard
            let box = env.pointee!.pointee.CallNonvirtualObjectMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })?.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz)
    }

    /// Call a nonvirtual Java method returning `boolean`.
    public func callNonvirtualBooleanMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Bool {
        env.pointee!.pointee.CallNonvirtualBooleanMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue }).value
    }

    /// Call a nonvirtual Java method returning `byte`.
    public func callNonvirtualByteMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int8 {
        env.pointee!.pointee.CallNonvirtualByteMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a nonvirtual Java method returning `char`.
    public func callNonvirtualCharMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> UInt16 {
        env.pointee!.pointee.CallNonvirtualCharMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a nonvirtual Java method returning `short`.
    public func callNonvirtualShortMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int16 {
        env.pointee!.pointee.CallNonvirtualShortMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a nonvirtual Java method returning `int`.
    public func callNonvirtualIntMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int32 {
        env.pointee!.pointee.CallNonvirtualIntMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a nonvirtual Java method returning `long`.
    public func callNonvirtualLongMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int64 {
        env.pointee!.pointee.CallNonvirtualLongMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a nonvirtual Java method returning `float`.
    public func callNonvirtualFloatMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Float {
        env.pointee!.pointee.CallNonvirtualFloatMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a nonvirtual Java method returning `double`.
    public func callNonvirtualDoubleMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Double {
        env.pointee!.pointee.CallNonvirtualDoubleMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a nonvirtual Java method returning `void`.
    public func callNonvirtualVoidMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) {
        env.pointee!.pointee.CallNonvirtualVoidMethodA!(env, object.ref.ref, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    // MARK: - Instance Field Lookup

    /// Look up the field ID of an instance field by name and type signature.
    ///
    /// This wraps JNI's `GetFieldID`.
    ///
    /// - Parameters:
    ///   - clazz: The class that declares the field.
    ///   - name: The field name (e.g., `"mFlags"`).
    ///   - sig: A `JSignatureItem` representing the JNI field signature (e.g., `.int`, `.object(...)`).
    /// - Returns: A `JFieldId` representing the field, or `nil` if lookup fails.
    public func getFieldId(
        clazz: JClass,
        name: String,
        sig: JSignatureItem
    ) -> JFieldId? {
        name.withCString { cname in
            sig.signature.withCString { csig in
                JFieldId(env.pointee!.pointee.GetFieldID!(env, clazz.ref, cname, csig))
            }
        }
    }

    // MARK: - Get Instance Field Values

    /// Get a reference to an object field from a Java instance.
    public func getObjectField(_ object: JObject, _ fieldId: JFieldId) -> JObject? {
        guard
            let box = env.pointee!.pointee.GetObjectField!(env, object.ref.ref, fieldId.id)?.box(JEnv(env))
        else { return nil }
        return JObject(box, object.clazz)
    }

    /// Get a `boolean` field from a Java instance.
    public func getBooleanField(_ object: JObject, _ fieldId: JFieldId) -> Bool {
        env.pointee!.pointee.GetBooleanField!(env, object.ref.ref, fieldId.id).value
    }

    /// Get a `byte` field from a Java instance.
    public func getByteField(_ object: JObject, _ fieldId: JFieldId) -> Int8 {
        env.pointee!.pointee.GetByteField!(env, object.ref.ref, fieldId.id)
    }

    /// Get a `char` field from a Java instance.
    public func getCharField(_ object: JObject, _ fieldId: JFieldId) -> UInt16 {
        env.pointee!.pointee.GetCharField!(env, object.ref.ref, fieldId.id)
    }

    /// Get a `short` field from a Java instance.
    public func getShortField(_ object: JObject, _ fieldId: JFieldId) -> Int16 {
        env.pointee!.pointee.GetShortField!(env, object.ref.ref, fieldId.id)
    }

    /// Get an `int` field from a Java instance.
    public func getIntField(_ object: JObject, _ fieldId: JFieldId) -> Int32 {
        env.pointee!.pointee.GetIntField!(env, object.ref.ref, fieldId.id)
    }

    /// Get a `long` field from a Java instance.
    public func getLongField(_ object: JObject, _ fieldId: JFieldId) -> Int64 {
        env.pointee!.pointee.GetLongField!(env, object.ref.ref, fieldId.id)
    }

    /// Get a `float` field from a Java instance.
    public func getFloatField(_ object: JObject, _ fieldId: JFieldId) -> Float {
        env.pointee!.pointee.GetFloatField!(env, object.ref.ref, fieldId.id)
    }

    /// Get a `double` field from a Java instance.
    public func getDoubleField(_ object: JObject, _ fieldId: JFieldId) -> Double {
        env.pointee!.pointee.GetDoubleField!(env, object.ref.ref, fieldId.id)
    }

    // MARK: - Set Instance Field Values

    /// Set an `object` field on a Java instance.
    public func setObjectField(_ object: JObject, _ fieldId: JFieldId, _ value: JObject?) {
        env.pointee!.pointee.SetObjectField!(env, object.ref.ref, fieldId.id, value?.ref.ref)
    }

    /// Set a `boolean` field on a Java instance.
    public func setBooleanField(_ object: JObject, _ fieldId: JFieldId, _ value: jboolean) {
        env.pointee!.pointee.SetBooleanField!(env, object.ref.ref, fieldId.id, value)
    }

    /// Set a `byte` field on a Java instance.
    public func setByteField(_ object: JObject, _ fieldId: JFieldId, _ value: jbyte) {
        env.pointee!.pointee.SetByteField!(env, object.ref.ref, fieldId.id, value)
    }

    /// Set a `char` field on a Java instance.
    public func setCharField(_ object: JObject, _ fieldId: JFieldId, _ value: jchar) {
        env.pointee!.pointee.SetCharField!(env, object.ref.ref, fieldId.id, value)
    }

    /// Set a `short` field on a Java instance.
    public func setShortField(_ object: JObject, _ fieldId: JFieldId, _ value: jshort) {
        env.pointee!.pointee.SetShortField!(env, object.ref.ref, fieldId.id, value)
    }

    /// Set an `int` field on a Java instance.
    public func setIntField(_ object: JObject, _ fieldId: JFieldId, _ value: jint) {
        env.pointee!.pointee.SetIntField!(env, object.ref.ref, fieldId.id, value)
    }

    /// Set a `long` field on a Java instance.
    public func setLongField(_ object: JObject, _ fieldId: JFieldId, _ value: Int64) {
        env.pointee!.pointee.SetLongField!(env, object.ref.ref, fieldId.id, value)
    }

    /// Set a `float` field on a Java instance.
    public func setFloatField(_ object: JObject, _ fieldId: JFieldId, _ value: Float) {
        env.pointee!.pointee.SetFloatField!(env, object.ref.ref, fieldId.id, value)
    }

    /// Set a `double` field on a Java instance.
    public func setDoubleField(_ object: JObject, _ fieldId: JFieldId, _ value: Double) {
        env.pointee!.pointee.SetDoubleField!(env, object.ref.ref, fieldId.id, value)
    }

    // MARK: - Static Method Lookup

    /// Look up a static method ID on a Java class.
    ///
    /// - Parameters:
    ///   - clazz: The `JClass` representing the Java class.
    ///   - name: The name of the static method to look up.
    ///   - sig: The JNI method signature as `JMethodSignature`, e.g. `()V`, `(Ljava/lang/String;)I`
    /// - Returns: A `JMethodId` if the method was found, or `nil` otherwise.
    public func getStaticMethodId(
        clazz: JClass,
        name: String,
        sig: JMethodSignature
    ) -> JMethodId? {
        name.withCString { cname in
            sig.signature.withCString { csig in
                JMethodId(env.pointee!.pointee.GetStaticMethodID!(env, clazz.ref, cname, csig))
            }
        }
    }

    // MARK: - Call Static Methods

    /// Call a static method returning an `Object`.
    public func callStaticObjectMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> JObject? {
        guard
            let box = env.pointee!.pointee.CallStaticObjectMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })?.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz)
    }

    /// Call a static method returning `boolean`.
    public func callStaticBooleanMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Bool {
        env.pointee!.pointee.CallStaticBooleanMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue }).value
    }

    /// Call a static method returning `byte`.
    public func callStaticByteMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int8 {
        env.pointee!.pointee.CallStaticByteMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a static method returning `char`.
    public func callStaticCharMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> UInt16 {
        env.pointee!.pointee.CallStaticCharMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a static method returning `short`.
    public func callStaticShortMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int16 {
        env.pointee!.pointee.CallStaticShortMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a static method returning `int`.
    public func callStaticIntMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int32 {
        env.pointee!.pointee.CallStaticIntMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a static method returning `long`.
    public func callStaticLongMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Int64 {
        env.pointee!.pointee.CallStaticLongMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a static method returning `float`.
    public func callStaticFloatMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Float {
        env.pointee!.pointee.CallStaticFloatMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a static method returning `double`.
    public func callStaticDoubleMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) -> Double {
        env.pointee!.pointee.CallStaticDoubleMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    /// Call a static method returning `void`.
    public func callStaticVoidMethod(
        clazz: JClass,
        methodId: JMethodId,
        args: UnsafePointer<jvalue>?
    ) {
        env.pointee!.pointee.CallStaticVoidMethodA!(env, clazz.ref, methodId.id, args?.map { $0.jValue })
    }

    // MARK: - Static Field Lookup

    /// Get the field ID of a static field on a Java class.
    ///
    /// - Parameters:
    ///   - clazz: The class that owns the static field.
    ///   - name: The name of the field.
    ///   - sig: The field type signature as `JSignatureItem`, e.g., `.int`, `.object(...)`.
    /// - Returns: A `JFieldId` if found, or `nil`.
    public func getStaticFieldId(
        clazz: JClass,
        name: String,
        sig: JSignatureItem
    ) -> JFieldId? {
        name.withCString { cname in
            sig.signature.withCString { csig in
                JFieldId(env.pointee!.pointee.GetStaticFieldID!(env, clazz.ref, cname, csig))
            }
        }
    }

    // MARK: - Get Static Field Values

    /// Get the value of a static field returning an object.
    ///
    /// - Parameters:
    ///   - clazz: The Java class containing the static field.
    ///   - fieldId: The field ID previously resolved using `getStaticFieldId`.
    /// - Returns: A wrapped `JObject` if the value is not null, or `nil`.
    public func getStaticObjectField(_ clazz: JClass, _ fieldId: JFieldId) -> JObject? {
        guard
            let box = env.pointee!.pointee.GetStaticObjectField!(env, clazz.ref, fieldId.id)?.box(JEnv(env))
        else { return nil }
        return JObject(box, clazz)
    }

    /// Get the value of a static field returning a `boolean`.
    public func getStaticBooleanField(_ clazz: JClass, _ fieldId: JFieldId) -> Bool {
        env.pointee!.pointee.GetStaticBooleanField!(env, clazz.ref, fieldId.id).value
    }

    /// Get the value of a static field returning a `byte`.
    public func getStaticByteField(_ clazz: JClass, _ fieldId: JFieldId) -> Int8 {
        env.pointee!.pointee.GetStaticByteField!(env, clazz.ref, fieldId.id)
    }

    /// Get the value of a static field returning a `char`.
    public func getStaticCharField(_ clazz: JClass, _ fieldId: JFieldId) -> UInt16 {
        env.pointee!.pointee.GetStaticCharField!(env, clazz.ref, fieldId.id)
    }

    /// Get the value of a static field returning a `short`.
    public func getStaticShortField(_ clazz: JClass, _ fieldId: JFieldId) -> Int16 {
        env.pointee!.pointee.GetStaticShortField!(env, clazz.ref, fieldId.id)
    }

    /// Get the value of a static field returning an `int`.
    public func getStaticIntField(_ clazz: JClass, _ fieldId: JFieldId) -> Int32 {
        env.pointee!.pointee.GetStaticIntField!(env, clazz.ref, fieldId.id)
    }

    /// Get the value of a static field returning a `long`.
    public func getStaticLongField(_ clazz: JClass, _ fieldId: JFieldId) -> Int64 {
        env.pointee!.pointee.GetStaticLongField!(env, clazz.ref, fieldId.id)
    }

    /// Get the value of a static field returning a `float`.
    public func getStaticFloatField(_ clazz: JClass, _ fieldId: JFieldId) -> Float {
        env.pointee!.pointee.GetStaticFloatField!(env, clazz.ref, fieldId.id)
    }

    /// Get the value of a static field returning a `double`.
    public func getStaticDoubleField(_ clazz: JClass, _ fieldId: JFieldId) -> Double {
        env.pointee!.pointee.GetStaticDoubleField!(env, clazz.ref, fieldId.id)
    }

    // MARK: - Set Static Field Values

    /// Set the value of a static field with an `Object`.
    ///
    /// - Parameters:
    ///   - clazz: The class containing the static field.
    ///   - fieldId: Field identifier previously resolved.
    ///   - value: The new object value to assign, or `nil` for null.
    public func setStaticObjectField(_ clazz: JClass, _ fieldId: JFieldId, _ value: JObject?) {
        env.pointee!.pointee.SetStaticObjectField!(env, clazz.ref, fieldId.id, value?.ref.ref)
    }

    /// Set a static `boolean` field.
    public func setStaticBooleanField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jboolean) {
        env.pointee!.pointee.SetStaticBooleanField!(env, clazz.ref, fieldId.id, value)
    }

    /// Set a static `byte` field.
    public func setStaticByteField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jbyte) {
        env.pointee!.pointee.SetStaticByteField!(env, clazz.ref, fieldId.id, value)
    }

    /// Set a static `char` field.
    public func setStaticCharField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jchar) {
        env.pointee!.pointee.SetStaticCharField!(env, clazz.ref, fieldId.id, value)
    }

    /// Set a static `short` field.
    public func setStaticShortField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jshort) {
        env.pointee!.pointee.SetStaticShortField!(env, clazz.ref, fieldId.id, value)
    }

    /// Set a static `int` field.
    public func setStaticIntField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jint) {
        env.pointee!.pointee.SetStaticIntField!(env, clazz.ref, fieldId.id, value)
    }

    /// Set a static `long` field.
    public func setStaticLongField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jlong) {
        env.pointee!.pointee.SetStaticLongField!(env, clazz.ref, fieldId.id, value)
    }

    /// Set a static `float` field.
    public func setStaticFloatField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jfloat) {
        env.pointee!.pointee.SetStaticFloatField!(env, clazz.ref, fieldId.id, value)
    }

    /// Set a static `double` field.
    public func setStaticDoubleField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jdouble) {
        env.pointee!.pointee.SetStaticDoubleField!(env, clazz.ref, fieldId.id, value)
    }

    // MARK: - Java Strings

    /// Create a new Java string from a UTF-16 buffer.
    ///
    /// This corresponds to the JNI `NewString` function. It creates a `jstring` from the provided buffer of 16-bit characters.
    ///
    /// - Parameters:
    ///   - chars: Pointer to the UTF-16 characters (`jchar` array).
    ///   - length: Number of characters in the array (not bytes).
    /// - Returns: A new `jstring`, or `nil` if creation fails.
    public func newString(chars: UnsafePointer<jchar>, length: jint) -> jstring? {
        env.pointee!.pointee.NewString!(env, chars, length)
    }

    /// Get the UTF-16 length of a Java string.
    ///
    /// Equivalent to `GetStringLength`. This returns the number of UTF-16 code units, not bytes.
    ///
    /// - Parameter string: The Java string.
    /// - Returns: Number of UTF-16 characters in the string.
    public func getStringLength(_ string: jstring) -> Int32 {
        env.pointee!.pointee.GetStringLength!(env, string)
    }

    /// Retrieve a pointer to the UTF-16 contents of a Java string.
    ///
    /// This returns a read-only buffer of `jchar` values that represent the UTF-16 encoding of the string.
    ///
    /// - Important: After use, you **must** call `releaseStringChars` to avoid memory leaks.
    ///
    /// - Parameters:
    ///   - string: Java `jstring` instance.
    ///   - isCopy: Optional pointer that receives whether the data is a copy.
    /// - Returns: Pointer to UTF-16 characters or `nil`.
    public func getStringChars(_ string: jstring, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafePointer<jchar>? {
        env.pointee!.pointee.GetStringChars!(env, string, isCopy)
    }

    /// Release the buffer obtained from `getStringChars`.
    ///
    /// - Parameters:
    ///   - string: The original Java string.
    ///   - chars: Pointer returned from `getStringChars`.
    public func releaseStringChars(_ string: jstring, chars: UnsafePointer<jchar>) {
        env.pointee!.pointee.ReleaseStringChars!(env, string, chars)
    }

    /// Create a new Java UTF-8 string from a Swift `String`.
    ///
    /// This wraps `NewStringUTF`, which creates a Java string from a C-style UTF-8 encoded string.
    ///
    /// - Parameter string: A Swift string (will be converted to C UTF-8).
    /// - Returns: A new `jstring`, or `nil` if creation fails.
    public func newStringUTF(_ string: String) -> jstring? {
        string.withCString {
            env.pointee!.pointee.NewStringUTF!(env, $0)
        }
    }

    /// Get the UTF-8 byte length of a Java string (not character count).
    ///
    /// Equivalent to `GetStringUTFLength`, this returns the number of bytes required to encode the Java string in UTF-8.
    ///
    /// - Parameter string: The Java string.
    /// - Returns: Number of bytes in UTF-8 encoding.
    public func getStringUTFLength(_ string: jstring) -> Int32 {
        env.pointee!.pointee.GetStringUTFLength!(env, string)
    }

    /// Retrieve a pointer to the UTF-8 encoded contents of a Java string.
    ///
    /// This pointer is valid until `releaseStringUTFChars` is called.
    ///
    /// - Important: After use, call `releaseStringUTFChars`.
    ///
    /// - Parameters:
    ///   - string: The Java `jstring`.
    ///   - isCopy: Optional pointer to receive copy status.
    /// - Returns: Pointer to null-terminated UTF-8 C string.
    public func getStringUTFChars(_ string: jstring, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafePointer<CChar>? {
        env.pointee!.pointee.GetStringUTFChars!(env, string, isCopy)
    }

    /// Release a UTF-8 string buffer previously acquired from `getStringUTFChars`.
    ///
    /// - Parameters:
    ///   - string: The original Java string.
    ///   - chars: Pointer obtained from `getStringUTFChars`.
    public func releaseStringUTFChars(_ string: jstring, chars: UnsafePointer<CChar>) {
        env.pointee!.pointee.ReleaseStringUTFChars!(env, string, chars)
    }

    // MARK: - Java Arrays

    /// Get the number of elements in a Java array.
    ///
    /// Works for any array type including `jobjectArray`, `jintArray`, etc.
    ///
    /// - Parameter array: A JNI `jarray` handle.
    /// - Returns: The number of elements in the array.
    public func getArrayLength(_ array: jarray) -> Int32 {
        env.pointee!.pointee.GetArrayLength!(env, array)
    }

    // MARK: - Object Arrays

    /// Create a new Java object array.
    ///
    /// This corresponds to JNI's `NewObjectArray`.
    ///
    /// - Parameters:
    ///   - length: Number of elements in the array.
    ///   - clazz: Class type of array elements.
    ///   - initialElement: Optional element to initialize all entries with.
    /// - Returns: A `JObjectArray` wrapping the created array.
    public func newObjectArray(length: jint, clazz: JClass, initialElement: JObject? = nil) -> JObjectArray? {
        guard let obj = env.pointee!.pointee.NewObjectArray!(env, length, clazz.ref, initialElement?.ref.ref) else { return nil }
        return JObjectArray(obj, clazz)
    }

    /// Get an element from a Java object array.
    ///
    /// - Parameters:
    ///   - array: The object array.
    ///   - index: The index of the element to retrieve.
    /// - Returns: A `JObject` wrapper for the element at that index.
    public func getObjectArrayElement(_ array: JObjectArray, index: jint) -> JObject? {
        let arrayRef = array.ref.ref.assumingMemoryBound(to: jobjectArray.self).pointee
        guard
            let box = env.pointee!.pointee.GetObjectArrayElement!(env, arrayRef, index)?.box(JEnv(env))
        else { return nil }
        return JObject(box, array.clazz)
    }

    /// Set an element in a Java object array.
    ///
    /// - Parameters:
    ///   - array: The target object array.
    ///   - index: Index of the element to set.
    ///   - value: The value to insert (may be `nil`).
    public func setObjectArrayElement(_ array: JObjectArray, index: jint, value: JObject?) {
        env.pointee!.pointee.SetObjectArrayElement!(env, array.ref.ref, index, value?.ref.ref)
    }

    // MARK: - Primitive Arrays

    /// Create a new Java array of `boolean` (jboolean).
    ///
    /// - Parameter length: Number of elements.
    /// - Returns: New `jbooleanArray`.
    public func newBooleanArray(length: jint) -> jbooleanArray? {
        env.pointee!.pointee.NewBooleanArray!(env, length)
    }

    /// Create a new Java array of `byte` (jbyte).
    public func newByteArray(length: jint) -> jbyteArray? {
        env.pointee!.pointee.NewByteArray!(env, length)
    }

    /// Create a new Java array of `char` (jchar).
    public func newCharArray(length: jint) -> jcharArray? {
        env.pointee!.pointee.NewCharArray!(env, length)
    }

    /// Create a new Java array of `short` (jshort).
    public func newShortArray(length: jint) -> jshortArray? {
        env.pointee!.pointee.NewShortArray!(env, length)
    }

    /// Create a new Java array of `int` (jint).
    public func newIntArray(length: jint) -> jintArray? {
        env.pointee!.pointee.NewIntArray!(env, length)
    }

    /// Create a new Java array of `long` (jlong).
    public func newLongArray(length: jint) -> jlongArray? {
        env.pointee!.pointee.NewLongArray!(env, length)
    }

    /// Create a new Java array of `float` (jfloat).
    public func newFloatArray(length: jint) -> jfloatArray? {
        env.pointee!.pointee.NewFloatArray!(env, length)
    }

    /// Create a new Java array of `double` (jdouble).
    public func newDoubleArray(length: jint) -> jdoubleArray? {
        env.pointee!.pointee.NewDoubleArray!(env, length)
    }

    // MARK: - Get Primitive Array Elements

    /// Get a pointer to the contents of a `boolean[]` Java array.
    ///
    /// - Parameters:
    ///   - array: A JNI `jbooleanArray`.
    ///   - isCopy: Optional pointer to receive JNI copy status (1 = copy, 0 = direct).
    /// - Returns: Pointer to native memory holding the array contents.
    public func getBooleanArrayElements(
        _ array: jbooleanArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jboolean>? {
        env.pointee!.pointee.GetBooleanArrayElements!(env, array, isCopy)
    }

    /// Get a pointer to a `byte[]` Java array.
    public func getByteArrayElements(
        _ array: jbyteArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jbyte>? {
        env.pointee!.pointee.GetByteArrayElements!(env, array, isCopy)
    }

    /// Get a pointer to a `char[]` Java array.
    public func getCharArrayElements(
        _ array: jcharArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jchar>? {
        env.pointee!.pointee.GetCharArrayElements!(env, array, isCopy)
    }

    /// Get a pointer to a `short[]` Java array.
    public func getShortArrayElements(
        _ array: jshortArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jshort>? {
        env.pointee!.pointee.GetShortArrayElements!(env, array, isCopy)
    }

    /// Get a pointer to an `int[]` Java array.
    public func getIntArrayElements(
        _ array: jintArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Int32>? {
        env.pointee!.pointee.GetIntArrayElements!(env, array, isCopy)
    }

    /// Get a pointer to a `long[]` Java array.
    public func getLongArrayElements(
        _ array: jlongArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Int64>? {
        env.pointee!.pointee.GetLongArrayElements!(env, array, isCopy)
    }

    /// Get a pointer to a `float[]` Java array.
    public func getFloatArrayElements(
        _ array: jfloatArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Float>? {
        env.pointee!.pointee.GetFloatArrayElements!(env, array, isCopy)
    }

    /// Get a pointer to a `double[]` Java array.
    public func getDoubleArrayElements(
        _ array: jdoubleArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Double>? {
        env.pointee!.pointee.GetDoubleArrayElements!(env, array, isCopy)
    }

    // MARK: - Release Primitive Array Elements

    /// Release memory returned by `getBooleanArrayElements`.
    ///
    /// - Parameters:
    ///   - array: The original `jbooleanArray`.
    ///   - elems: Pointer previously returned.
    ///   - mode: `0` to copy back, `JNI_COMMIT` to copy without free, `JNI_ABORT` to discard changes.
    public func releaseBooleanArrayElements(
        _ array: jbooleanArray,
        _ elems: UnsafeMutablePointer<jboolean>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseBooleanArrayElements!(env, array, elems, mode)
    }

    /// Release memory for `byte[]`.
    public func releaseByteArrayElements(
        _ array: jbyteArray,
        _ elems: UnsafeMutablePointer<jbyte>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseByteArrayElements!(env, array, elems, mode)
    }

    /// Release memory for `char[]`.
    public func releaseCharArrayElements(
        _ array: jcharArray,
        _ elems: UnsafeMutablePointer<jchar>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseCharArrayElements!(env, array, elems, mode)
    }

    /// Release memory for `short[]`.
    public func releaseShortArrayElements(
        _ array: jshortArray,
        _ elems: UnsafeMutablePointer<jshort>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseShortArrayElements!(env, array, elems, mode)
    }

    /// Release memory for `int[]`.
    public func releaseIntArrayElements(
        _ array: jintArray,
        _ elems: UnsafeMutablePointer<jint>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseIntArrayElements!(env, array, elems, mode)
    }

    /// Release memory for `long[]`.
    public func releaseLongArrayElements(
        _ array: jlongArray,
        _ elems: UnsafeMutablePointer<jlong>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseLongArrayElements!(env, array, elems, mode)
    }

    /// Release memory for `float[]`.
    public func releaseFloatArrayElements(
        _ array: jfloatArray,
        _ elems: UnsafeMutablePointer<jfloat>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseFloatArrayElements!(env, array, elems, mode)
    }

    /// Release memory for `double[]`.
    public func releaseDoubleArrayElements(
        _ array: jdoubleArray,
        _ elems: UnsafeMutablePointer<jdouble>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseDoubleArrayElements!(env, array, elems, mode)
    }

    // MARK: - Array Region Getters

    /// Copy a region from a Java `boolean[]` array into a native buffer.
    ///
    /// - Parameters:
    ///   - array: The Java boolean array.
    ///   - start: Starting index to copy from.
    ///   - length: Number of elements to copy.
    ///   - buffer: Pointer to destination buffer to write into.
    public func getBooleanArrayRegion(
        _ array: jbooleanArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jboolean>
    ) {
        env.pointee!.pointee.GetBooleanArrayRegion!(env, array, start, length, buffer)
    }

    /// Copy a region from a Java `byte[]` array.
    public func getByteArrayRegion(
        _ array: jbyteArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jbyte>
    ) {
        env.pointee!.pointee.GetByteArrayRegion!(env, array, start, length, buffer)
    }

    /// Copy a region from a Java `char[]` array.
    public func getCharArrayRegion(
        _ array: jcharArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jchar>
    ) {
        env.pointee!.pointee.GetCharArrayRegion!(env, array, start, length, buffer)
    }

    /// Copy a region from a Java `short[]` array.
    public func getShortArrayRegion(
        _ array: jshortArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jshort>
    ) {
        env.pointee!.pointee.GetShortArrayRegion!(env, array, start, length, buffer)
    }

    /// Copy a region from a Java `int[]` array.
    public func getIntArrayRegion(
        _ array: jintArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jint>
    ) {
        env.pointee!.pointee.GetIntArrayRegion!(env, array, start, length, buffer)
    }

    /// Copy a region from a Java `long[]` array.
    public func getLongArrayRegion(
        _ array: jlongArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jlong>
    ) {
        env.pointee!.pointee.GetLongArrayRegion!(env, array, start, length, buffer)
    }

    /// Copy a region from a Java `float[]` array.
    public func getFloatArrayRegion(
        _ array: jfloatArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jfloat>
    ) {
        env.pointee!.pointee.GetFloatArrayRegion!(env, array, start, length, buffer)
    }

    /// Copy a region from a Java `double[]` array.
    public func getDoubleArrayRegion(
        _ array: jdoubleArray,
        start: jint,
        length: jint,
        buffer: UnsafeMutablePointer<jdouble>
    ) {
        env.pointee!.pointee.GetDoubleArrayRegion!(env, array, start, length, buffer)
    }

    // MARK: - Array Region Setters

    /// Set a region of a Java `boolean[]` array from native buffer data.
    ///
    /// - Parameters:
    ///   - array: The Java array to update.
    ///   - start: The starting index to write into.
    ///   - length: Number of elements to write.
    ///   - buffer: Native buffer containing the data to write.
    public func setBooleanArrayRegion(
        _ array: jbooleanArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jboolean>
    ) {
        env.pointee!.pointee.SetBooleanArrayRegion!(env, array, start, length, buffer)
    }

    /// Set region of `byte[]` array.
    public func setByteArrayRegion(
        _ array: jbyteArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jbyte>
    ) {
        env.pointee!.pointee.SetByteArrayRegion!(env, array, start, length, buffer)
    }

    /// Set region of `char[]` array.
    public func setCharArrayRegion(
        _ array: jcharArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jchar>
    ) {
        env.pointee!.pointee.SetCharArrayRegion!(env, array, start, length, buffer)
    }

    /// Set region of `short[]` array.
    public func setShortArrayRegion(
        _ array: jshortArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jshort>
    ) {
        env.pointee!.pointee.SetShortArrayRegion!(env, array, start, length, buffer)
    }

    /// Set region of `int[]` array.
    public func setIntArrayRegion(
        _ array: jintArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jint>
    ) {
        env.pointee!.pointee.SetIntArrayRegion!(env, array, start, length, buffer)
    }

    /// Set region of `long[]` array.
    public func setLongArrayRegion(
        _ array: jlongArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jlong>
    ) {
        env.pointee!.pointee.SetLongArrayRegion!(env, array, start, length, buffer)
    }

    /// Set region of `float[]` array.
    public func setFloatArrayRegion(
        _ array: jfloatArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jfloat>
    ) {
        env.pointee!.pointee.SetFloatArrayRegion!(env, array, start, length, buffer)
    }

    /// Set region of `double[]` array.
    public func setDoubleArrayRegion(
        _ array: jdoubleArray,
        start: jint,
        length: jint,
        buffer: UnsafePointer<jdouble>
    ) {
        env.pointee!.pointee.SetDoubleArrayRegion!(env, array, start, length, buffer)
    }

    // MARK: - Native Method Registration

    /// Register native methods with a Java class.
    ///
    /// - Parameters:
    ///   - clazz: The class to register native methods with.
    ///   - methods: Pointer to an array of `JNINativeMethod`.
    ///   - count: Number of methods to register.
    /// - Returns: JNI status code (`JNI_OK` on success).
    public func registerNatives(clazz: JClass, methods: UnsafePointer<JNINativeMethod>, count: jint) -> Int32 {
        env.pointee!.pointee.RegisterNatives!(env, clazz.ref, methods, count)
    }

    /// Unregister all native methods previously registered for the given class.
    ///
    /// - Parameter clazz: The class to unregister methods from.
    /// - Returns: JNI status code (`JNI_OK` on success).
    public func unregisterNatives(clazz: JClass) -> Int32 {
        env.pointee!.pointee.UnregisterNatives!(env, clazz.ref)
    }

    // MARK: - Monitor (synchronized) Helpers

    /// Enter the monitor associated with a Java object (like `synchronized` block).
    public func monitorEnter(_ object: JObject) -> Int32 {
        env.pointee!.pointee.MonitorEnter!(env, object.ref.ref)
    }

    /// Exit the monitor associated with a Java object.
    public func monitorExit(_ object: JObject) -> Int32 {
        env.pointee!.pointee.MonitorExit!(env, object.ref.ref)
    }

    // MARK: - JVM Access

    /// Get the `JavaVM*` associated with this `JNIEnv`.
    ///
    /// - Returns: The pointer to the `JavaVM`, or `nil` if retrieval fails.
    public func getJavaVM() -> UnsafeMutablePointer<JavaVM?>? {
        var vm: UnsafeMutablePointer<JavaVM?>?
        _ = env.pointee!.pointee.GetJavaVM!(env, &vm)
        return vm
    }

    // MARK: - String Region Access

    /// Copy a region of a Java string's UTF-16 characters into a buffer.
    public func getStringRegion(_ string: jstring, start: jint, length: jint, buffer: UnsafeMutablePointer<jchar>) {
        env.pointee!.pointee.GetStringRegion!(env, string, start, length, buffer)
    }

    /// Copy a region of a Java string's UTF-8 characters into a buffer.
    public func getStringUTFRegion(_ string: jstring, start: jint, length: jint, buffer: UnsafeMutablePointer<CChar>) {
        env.pointee!.pointee.GetStringUTFRegion!(env, string, start, length, buffer)
    }

    // MARK: - Critical Array Access

    /// Get a pointer to a primitive array's contents in a critical section (fastest access).
    ///
    /// - Warning: The GC is disabled while the pointer is held.
    public func getPrimitiveArrayCritical(_ array: jarray, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafeMutableRawPointer? {
        env.pointee!.pointee.GetPrimitiveArrayCritical!(env, array, isCopy)
    }

    /// Release the pointer acquired from `getPrimitiveArrayCritical`.
    ///
    /// - Parameter mode: Either 0, `JNI_COMMIT`, or `JNI_ABORT`.
    public func releasePrimitiveArrayCritical(_ array: jarray, pointer: UnsafeMutableRawPointer, mode: jint = 0) {
        env.pointee!.pointee.ReleasePrimitiveArrayCritical!(env, array, pointer, mode)
    }

    // MARK: - Critical String Access

    /// Get a pointer to the characters of a Java string in a critical section.
    ///
    /// - Warning: The GC is disabled while the pointer is held.
    public func getStringCritical(_ string: jstring, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafePointer<jchar>? {
        env.pointee!.pointee.GetStringCritical!(env, string, isCopy)
    }

    /// Release a string pointer acquired from `getStringCritical`.
    public func releaseStringCritical(_ string: jstring, chars: UnsafePointer<jchar>) {
        env.pointee!.pointee.ReleaseStringCritical!(env, string, chars)
    }

    // MARK: - Weak Global Refs

    /// Create a weak global reference to a Java object.
    ///
    /// Weak references allow the JVM to GC the object when no strong references exist.
    public func newWeakGlobalRef(_ obj: JObject) -> jweak? {
        env.pointee!.pointee.NewWeakGlobalRef!(env, obj.ref.ref)
    }

    /// Delete a previously created weak global reference.
    public func deleteWeakGlobalRef(_ ref: jweak) {
        env.pointee!.pointee.DeleteWeakGlobalRef!(env, ref)
    }

    // MARK: - Exception Check

    /// Check if a Java exception is currently pending on this thread.
    ///
    /// - Returns: `true` if an exception has occurred.
    public func exceptionCheck() -> Bool {
        env.pointee!.pointee.ExceptionCheck!(env).value
    }

    // MARK: - Direct ByteBuffer

    /// Create a `java.nio.DirectByteBuffer` from a raw memory address.
    ///
    /// - Parameters:
    ///   - address: Pointer to the memory to wrap.
    ///   - capacity: Number of bytes the buffer should expose.
    public func newDirectByteBuffer(address: UnsafeMutableRawPointer, capacity: Int64) -> jobject? {
        env.pointee!.pointee.NewDirectByteBuffer!(env, address, capacity)
    }

    /// Get the memory address backing a direct byte buffer.
    public func getDirectBufferAddress(_ buffer: JObject) -> UnsafeMutableRawPointer? {
        env.pointee!.pointee.GetDirectBufferAddress!(env, buffer.ref.ref)
    }

    /// Get the capacity in bytes of a direct byte buffer.
    public func getDirectBufferCapacity(_ buffer: JObject) -> Int64 {
        env.pointee!.pointee.GetDirectBufferCapacity!(env, buffer.ref.ref)
    }

    // MARK: - Reference Type Inspection

    /// Inspect the type of a JNI object reference (`local`, `global`, `weak global`).
    ///
    /// - Returns: A `JObjectRefType` describing the reference type.
    public func getObjectRefType(_ obj: JObject) -> JObjectRefType {
        JObjectRefType(env.pointee!.pointee.GetObjectRefType!(env, obj.ref.ref))
    }
}
#endif
