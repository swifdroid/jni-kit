//
//  JEnv.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

import Android

/// A safe and ergonomic wrapper around `JNIEnv*` for use in Swift 6.1+
///
/// This wrapper hides unsafe pointer access and provides convenience methods for
/// working with Java classes, methods, fields, strings, and objects.
public struct JEnv: @unchecked Sendable {
    /// The raw JNI environment pointer (thread-local)
    public let env: UnsafeMutablePointer<JNIEnv?>

    public init(_ env: UnsafeMutablePointer<JNIEnv?>) {
        self.env = env
    }

    public init?(_ env: UnsafeMutablePointer<JNIEnv?>?) {
        guard let env else { return nil }
        self.env = env
    }
}

extension JEnv {
    /// Convenience helper to get `JNIEnvWrapper` for the current thread using the stored `JavaVM`.
    ///
    /// This safely attaches the current thread to the JVM and returns a wrapped `JNIEnv` pointer.
    public static func current() async -> JEnv? {
        guard let vm = await JNIKit.shared.vm else { return nil }
        return vm.attachCurrentThread()
    }
}

extension JEnv {
    /// Get the JNI version supported by the JVM.
    public func getVersion() -> Int32 {
        env.pointee!.pointee.GetVersion(env)
    }

    /// Define a new Java class from raw bytecode.
    ///
    /// - Parameters:
    ///   - name: Fully qualified class name
    ///   - loader: A class loader object (may be `nil`)
    ///   - buf: Pointer to class bytecode
    ///   - size: Length of bytecode buffer
    public func defineClass(name: JClassName, loader: JObject?, buf: UnsafePointer<jbyte>, size: jint) -> JClass? {
        name.path.withCString {
            JClass(env.pointee!.pointee.DefineClass!(env, $0, loader?.ref, buf, size), name)
        }
    }

    /// Find a class by name using the current class loader.
    public func findClass(_ name: JClassName) -> JClass? {
        name.path.withCString {
            JClass(env.pointee!.pointee.FindClass!(env, $0), name)
        }
    }

    /// Convert a Java `Method` object to a native method Id.
    public func fromReflectedMethod(_ method: JObject) -> JMethodIdRefWrapper? {
        JMethodIdRefWrapper(env.pointee!.pointee.FromReflectedMethod!(env, method.ref))
    }

    /// Convert a Java `Field` object to a native field Id.
    public func fromReflectedField(_ field: JObject) -> JFieldId? {
        JFieldId(env.pointee!.pointee.FromReflectedField!(env, field.ref))
    }

    /// Convert a native method Id to a Java `Method` or `Constructor` object.
    ///
    /// - Parameters:
    ///   - clazz: The declaring class
    ///   - methodId: The native method Id
    ///   - isStatic: Whether it's a static method
    public func toReflectedMethod(clazz: JClass, methodId: JMethodIdRefWrapper, isStatic: Bool) -> JObject? {
        JObject(env.pointee!.pointee.ToReflectedMethod!(env, clazz.ref, methodId.id, isStatic.jboolean), clazz)
    }

    /// Get the superclass of a class.
    public func getSuperclass(of clazz: JClass) -> JClass? {
        JClass(env.pointee!.pointee.GetSuperclass!(env, clazz.ref), clazz.name)
    }

    /// Check if a class is assignable from another.
    public func isAssignable(from clazz1: JClass, to clazz2: JClass) -> Bool {
        env.pointee!.pointee.IsAssignableFrom!(env, clazz1.ref, clazz2.ref).value
    }

    /// Convert a native field Id to a Java `Field` object.
    public func toReflectedField(clazz: JClass, fieldId: JFieldId, isStatic: Bool) -> JObject? {
        JObject(env.pointee!.pointee.ToReflectedField!(env, clazz.ref, fieldId.id, isStatic.jboolean), clazz)
    }

    /// Throw an existing Java exception object.
    public func throwException(_ throwable: jthrowable) -> Int32 {
        env.pointee!.pointee.Throw!(env, throwable)
    }

    /// Throw a new Java exception by class and message.
    public func throwNew(clazz: JClass, message: String) -> Int32 {
        message.withCString {
            env.pointee!.pointee.ThrowNew!(env, clazz.ref, $0)
        }
    }

    /// Check if an exception is pending.
    public func exceptionOccurred() async -> JThrowableRefWrapper? {
        guard let throwable = env.pointee!.pointee.ExceptionOccurred!(env) else { return nil }
        guard let clazz = await JClass.load("java/lang/Throwable") else { return nil }
        return await JThrowableRefWrapper(throwable, clazz)
    }

    /// Print the stack trace of a pending exception to stderr.
    public func exceptionDescribe() {
        env.pointee!.pointee.ExceptionDescribe!(env)
    }

    /// Clear any pending exception.
    public func exceptionClear() {
        env.pointee!.pointee.ExceptionClear!(env)
    }

    /// Report a fatal error to the JVM and abort.
    public func fatalError(_ message: String) {
        message.withCString {
            env.pointee!.pointee.FatalError!(env, $0)
        }
    }

    /// Throws a Java exception object (previously caught or created).
    ///
    /// Equivalent to calling `(*env)->Throw(env, throwable)` in JNI.
    ///
    /// - Parameter throwable: A `jthrowable` or `jobject` that is a subclass of `java.lang.Throwable`
    /// - Returns: JNI status code (`JNI_OK`, `JNI_ERR`, etc.)
    public func throwObject(_ throwable: jobject) -> Int32 {
        env.pointee!.pointee.Throw!(env, throwable)
    }

    /// Throws a Java exception object (previously caught or created).
    ///
    /// Equivalent to calling `(*env)->Throw(env, throwable)` in JNI.
    ///
    /// - Parameter throwable: A `JThrowableRefWrapper` which contains `jthrowable` that is a subclass of `java.lang.Throwable`
    /// - Returns: JNI status code (`JNI_OK`, `JNI_ERR`, etc.)
    public func throwObject(_ throwable: JThrowableRefWrapper) -> JNIStatus {
        JNIStatus.init(fromRawValue: env.pointee!.pointee.Throw!(env, throwable.ref))
    }

    /// Push a new local reference frame with a given capacity.
    ///
    /// - Parameter capacity: Number of local references allowed in the frame
    public func pushLocalFrame(capacity: jint) -> Int32 {
        env.pointee!.pointee.PushLocalFrame!(env, capacity)
    }

    /// Pop the current local reference frame and return a retained local reference.
    ///
    /// - Parameter result: Local reference to retain when popping
    /// - Returns: A new reference to `result` or `nil`
    public func popLocalFrame(result: JObject?) -> JObject? {
        JObject(env.pointee!.pointee.PopLocalFrame!(env, result?.ref), result?.clazz)
    }

    /// Create a new global reference from a local reference.
    public func newGlobalRef(_ obj: JObject) -> JObject? {
        JObject(env.pointee!.pointee.NewGlobalRef!(env, obj.ref), obj.clazz)
    }

    /// Delete a previously created global reference.
    public func deleteGlobalRef(_ globalRef: JObject) {
        env.pointee!.pointee.DeleteGlobalRef!(env, globalRef.ref)
    }

    /// Delete a local reference.
    public func deleteLocalRef(_ localRef: JObject) {
        env.pointee!.pointee.DeleteLocalRef!(env, localRef.ref)
    }

    /// Check if two references refer to the same Java object.
    public func isSameObject(_ obj1: JObject, _ obj2: JObject) -> Bool {
        env.pointee!.pointee.IsSameObject!(env, obj1.ref, obj2.ref).value
    }

    /// Create a new local reference to an existing object.
    public func newLocalRef(_ obj: JObject) -> JObject? {
        JObject(env.pointee!.pointee.NewLocalRef!(env, obj.ref), obj.clazz)
    }

    /// Ensure space for a given number of local references.
    ///
    /// - Returns: `JNI_OK` if successful
    public func ensureLocalCapacity(_ capacity: jint) -> Int32 {
        env.pointee!.pointee.EnsureLocalCapacity!(env, capacity)
    }

    /// Allocate a new instance of a Java class without calling a constructor.
    public func allocObject(_ clazz: JClass) -> JObject? {
        JObject(env.pointee!.pointee.AllocObject!(env, clazz.ref), clazz)
    }

    // MARK: - Object Creation

    /// Create a new Java object using a constructor (jvalue array).
    public func newObject(
        clazz: JClass,
        constructor: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> JObject? {
        guard let obj = env.pointee!.pointee.NewObjectA!(env, clazz.ref, constructor.id, args) else { return nil }
        return JObject(obj, clazz)
    }

    // MARK: - Object Info

    /// Get the class of a Java object.
    public func getObjectClass(_ object: JObject) -> JClass? {
        JClass(env.pointee!.pointee.GetObjectClass!(env, object.ref), object.className)
    }

    /// Check if a Java object is an instance of a specific class.
    public func isInstanceOf(_ object: JObject, _ clazz: JClass) -> Bool {
        env.pointee!.pointee.IsInstanceOf!(env, object.ref, clazz.ref) == UInt8(JNI_TRUE)
    }

    // MARK: - Method Lookup

    /// Look up a method Id for an instance method.
    ///
    /// - Parameters:
    ///   - clazz: Class to look in
    ///   - name: Method name
    ///   - sig: JNI method signature
    public func getMethodId(
        clazz: JClass,
        name: String,
        sig: JMethodSignature
    ) -> JMethodIdRefWrapper? {
        name.withCString { cname in
            sig.signature.withCString { csig in
                JMethodIdRefWrapper(env.pointee!.pointee.GetMethodID!(env, clazz.ref, cname, csig))
            }
        }
    }

    // MARK: - CallObjectMethod

    /// Call a Java method returning `Object` (jvalue array).
    public func callObjectMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> JObject? {
        JObject(env.pointee!.pointee.CallObjectMethodA!(env, object.ref, methodId.id, args), object.clazz)
    }

    // MARK: - CallBooleanMethod

    /// Call a Java method returning `boolean` (jvalue array).
    public func callBooleanMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Bool {
        env.pointee!.pointee.CallBooleanMethodA!(env, object.ref, methodId.id, args).value
    }

    // MARK: - CallByteMethod

    /// Call a Java method returning `byte` (jvalue array).
    public func callByteMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int8 {
        env.pointee!.pointee.CallByteMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallCharMethod

    /// Call a Java method returning `char` (jvalue array).
    public func callCharMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> UInt16 {
        env.pointee!.pointee.CallCharMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallShortMethod

    /// Call a Java method returning `short` (jvalue array).
    public func callShortMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int16 {
        env.pointee!.pointee.CallShortMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallIntMethod

    /// Call a Java method returning `int` (jvalue array).
    public func callIntMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int32 {
        env.pointee!.pointee.CallIntMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallLongMethod

    /// Call a Java method returning `long` (jvalue array).
    public func callLongMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int64 {
        env.pointee!.pointee.CallLongMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallFloatMethod

    /// Call a Java method returning `float` (jvalue array).
    public func callFloatMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Float {
        env.pointee!.pointee.CallFloatMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallDoubleMethod

    /// Call a Java method returning `double` (jvalue array).
    public func callDoubleMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Double {
        env.pointee!.pointee.CallDoubleMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallVoidMethod

    /// Call a Java method returning `void` (jvalue array).
    public func callVoidMethod(
        object: JObject,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) {
        env.pointee!.pointee.CallVoidMethodA!(env, object.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualObjectMethod

    /// Call a nonvirtual method returning `Object` (jvalue array).
    public func callNonvirtualObjectMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> JObject? {
        JObject(env.pointee!.pointee.CallNonvirtualObjectMethodA!(env, object.ref, clazz.ref, methodId.id, args), clazz)
    }

    // MARK: - CallNonvirtualBooleanMethod

    /// Call a nonvirtual method returning `boolean` (jvalue array).
    public func callNonvirtualBooleanMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Bool {
        env.pointee!.pointee.CallNonvirtualBooleanMethodA!(env, object.ref, clazz.ref, methodId.id, args).value
    }

    // MARK: - CallNonvirtualByteMethod

    /// Call a nonvirtual method returning `byte` (jvalue array).
    public func callNonvirtualByteMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int8 {
        env.pointee!.pointee.CallNonvirtualByteMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualCharMethod

    /// Call a nonvirtual method returning `char` (jvalue array).
    public func callNonvirtualCharMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> UInt16 {
        env.pointee!.pointee.CallNonvirtualCharMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualShortMethod

    /// Call a nonvirtual method returning `short` (jvalue array).
    public func callNonvirtualShortMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int16 {
        env.pointee!.pointee.CallNonvirtualShortMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualIntMethod

    /// Call a nonvirtual method returning `int` (jvalue array).
    public func callNonvirtualIntMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int32 {
        env.pointee!.pointee.CallNonvirtualIntMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualLongMethod

    /// Call a nonvirtual method returning `long` (jvalue array).
    public func callNonvirtualLongMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int64 {
        env.pointee!.pointee.CallNonvirtualLongMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualFloatMethod

    /// Call a nonvirtual method returning `float` (jvalue array).
    public func callNonvirtualFloatMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Float {
        env.pointee!.pointee.CallNonvirtualFloatMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualDoubleMethod

    /// Call a nonvirtual method returning `double` (jvalue array).
    public func callNonvirtualDoubleMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Double {
        env.pointee!.pointee.CallNonvirtualDoubleMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - CallNonvirtualVoidMethod

    /// Call a nonvirtual method returning `void` (jvalue array).
    public func callNonvirtualVoidMethod(
        object: JObject,
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) {
        env.pointee!.pointee.CallNonvirtualVoidMethodA!(env, object.ref, clazz.ref, methodId.id, args)
    }

    // MARK: - Instance Field Access

    /// Look up the field Id of an instance field.
    ///
    /// - Parameters:
    ///   - clazz: The class that declares the field
    ///   - name: Field name
    ///   - sig: JNI signature (e.g. `"I"` for `int`)
    /// - Returns: A `JFieldId`, or `nil` if not found
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

    // MARK: - Get Instance Fields

    public func getObjectField(_ object: JObject, _ fieldId: JFieldId) -> JObject? {
        JObject(env.pointee!.pointee.GetObjectField!(env, object.ref, fieldId.id), object.clazz)
    }

    public func getBooleanField(_ object: JObject, _ fieldId: JFieldId) -> Bool {
        env.pointee!.pointee.GetBooleanField!(env, object.ref, fieldId.id).value
    }

    public func getByteField(_ object: JObject, _ fieldId: JFieldId) -> Int8 {
        env.pointee!.pointee.GetByteField!(env, object.ref, fieldId.id)
    }

    public func getCharField(_ object: JObject, _ fieldId: JFieldId) -> UInt16 {
        env.pointee!.pointee.GetCharField!(env, object.ref, fieldId.id)
    }

    public func getShortField(_ object: JObject, _ fieldId: JFieldId) -> Int16 {
        env.pointee!.pointee.GetShortField!(env, object.ref, fieldId.id)
    }

    public func getIntField(_ object: JObject, _ fieldId: JFieldId) -> Int32 {
        env.pointee!.pointee.GetIntField!(env, object.ref, fieldId.id)
    }

    public func getLongField(_ object: JObject, _ fieldId: JFieldId) -> Int64 {
        env.pointee!.pointee.GetLongField!(env, object.ref, fieldId.id)
    }

    public func getFloatField(_ object: JObject, _ fieldId: JFieldId) -> Float {
        env.pointee!.pointee.GetFloatField!(env, object.ref, fieldId.id)
    }

    public func getDoubleField(_ object: JObject, _ fieldId: JFieldId) -> Double {
        env.pointee!.pointee.GetDoubleField!(env, object.ref, fieldId.id)
    }

    // MARK: - Set Instance Fields

    public func setObjectField(_ object: JObject, _ fieldId: JFieldId, _ value: JObject?) {
        env.pointee!.pointee.SetObjectField!(env, object.ref, fieldId.id, value?.ref)
    }

    public func setBooleanField(_ object: JObject, _ fieldId: JFieldId, _ value: jboolean) {
        env.pointee!.pointee.SetBooleanField!(env, object.ref, fieldId.id, value)
    }

    public func setByteField(_ object: JObject, _ fieldId: JFieldId, _ value: jbyte) {
        env.pointee!.pointee.SetByteField!(env, object.ref, fieldId.id, value)
    }

    public func setCharField(_ object: JObject, _ fieldId: JFieldId, _ value: jchar) {
        env.pointee!.pointee.SetCharField!(env, object.ref, fieldId.id, value)
    }

    public func setShortField(_ object: JObject, _ fieldId: JFieldId, _ value: jshort) {
        env.pointee!.pointee.SetShortField!(env, object.ref, fieldId.id, value)
    }

    public func setIntField(_ object: JObject, _ fieldId: JFieldId, _ value: jint) {
        env.pointee!.pointee.SetIntField!(env, object.ref, fieldId.id, value)
    }

    public func setLongField(_ object: JObject, _ fieldId: JFieldId, _ value: Int64) {
        env.pointee!.pointee.SetLongField!(env, object.ref, fieldId.id, value)
    }

    public func setFloatField(_ object: JObject, _ fieldId: JFieldId, _ value: Float) {
        env.pointee!.pointee.SetFloatField!(env, object.ref, fieldId.id, value)
    }

    public func setDoubleField(_ object: JObject, _ fieldId: JFieldId, _ value: Double) {
        env.pointee!.pointee.SetDoubleField!(env, object.ref, fieldId.id, value)
    }

    // MARK: - Static Method Lookup

    /// Look up a static method Id on a class.
    ///
    /// - Parameters:
    ///   - clazz: Java class reference
    ///   - name: Static method name
    ///   - sig: JNI method signature, for example:
    ///                             `()V` -> `.returning(.void)`
    ///                             `(Ljava/lang/String;)I` -> `.returning(.int, "java/lang/String")`
    public func getStaticMethodId(
        clazz: JClass,
        name: String,
        sig: JMethodSignature
    ) -> JMethodIdRefWrapper? {
        name.withCString { cname in
            sig.signature.withCString { csig in
                JMethodIdRefWrapper(env.pointee!.pointee.GetStaticMethodID!(env, clazz.ref, cname, csig))
            }
        }
    }

    // MARK: - CallStaticObjectMethod

    /// Call a static method returning `Object` (jvalue array).
    public func callStaticObjectMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> JObject? {
        JObject(env.pointee!.pointee.CallStaticObjectMethodA!(env, clazz.ref, methodId.id, args), clazz)
    }

    // MARK: - CallStaticBooleanMethod

    public func callStaticBooleanMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Bool {
        env.pointee!.pointee.CallStaticBooleanMethodA!(env, clazz.ref, methodId.id, args).value
    }

    // MARK: - CallStaticByteMethod

    public func callStaticByteMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int8 {
        env.pointee!.pointee.CallStaticByteMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - CallStaticCharMethod

    public func callStaticCharMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> UInt16 {
        env.pointee!.pointee.CallStaticCharMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - CallStaticShortMethod

    public func callStaticShortMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int16 {
        env.pointee!.pointee.CallStaticShortMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - CallStaticIntMethod

    public func callStaticIntMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int32 {
        env.pointee!.pointee.CallStaticIntMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - CallStaticLongMethod

    public func callStaticLongMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Int64 {
        env.pointee!.pointee.CallStaticLongMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - CallStaticFloatMethod

    public func callStaticFloatMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Float {
        env.pointee!.pointee.CallStaticFloatMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - CallStaticDoubleMethod

    public func callStaticDoubleMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) -> Double {
        env.pointee!.pointee.CallStaticDoubleMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - CallStaticVoidMethod

    /// Call a static method returning `void` (jvalue array).
    public func callStaticVoidMethod(
        clazz: JClass,
        methodId: JMethodIdRefWrapper,
        args: UnsafePointer<jvalue>?
    ) {
        env.pointee!.pointee.CallStaticVoidMethodA!(env, clazz.ref, methodId.id, args)
    }

    // MARK: - Static Field Access

    /// Look up a static field Id.
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

    // MARK: - Get Static Fields

    public func getStaticObjectField(_ clazz: JClass, _ fieldId: JFieldId) -> JObject? {
        JObject(env.pointee!.pointee.GetStaticObjectField!(env, clazz.ref, fieldId.id), clazz)
    }

    public func getStaticBooleanField(_ clazz: JClass, _ fieldId: JFieldId) -> Bool {
        env.pointee!.pointee.GetStaticBooleanField!(env, clazz.ref, fieldId.id).value
    }

    public func getStaticByteField(_ clazz: JClass, _ fieldId: JFieldId) -> Int8 {
        env.pointee!.pointee.GetStaticByteField!(env, clazz.ref, fieldId.id)
    }

    public func getStaticCharField(_ clazz: JClass, _ fieldId: JFieldId) -> UInt16 {
        env.pointee!.pointee.GetStaticCharField!(env, clazz.ref, fieldId.id)
    }

    public func getStaticShortField(_ clazz: JClass, _ fieldId: JFieldId) -> Int16 {
        env.pointee!.pointee.GetStaticShortField!(env, clazz.ref, fieldId.id)
    }

    public func getStaticIntField(_ clazz: JClass, _ fieldId: JFieldId) -> Int32 {
        env.pointee!.pointee.GetStaticIntField!(env, clazz.ref, fieldId.id)
    }

    public func getStaticLongField(_ clazz: JClass, _ fieldId: JFieldId) -> Int64 {
        env.pointee!.pointee.GetStaticLongField!(env, clazz.ref, fieldId.id)
    }

    public func getStaticFloatField(_ clazz: JClass, _ fieldId: JFieldId) -> Float {
        env.pointee!.pointee.GetStaticFloatField!(env, clazz.ref, fieldId.id)
    }

    public func getStaticDoubleField(_ clazz: JClass, _ fieldId: JFieldId) -> Double {
        env.pointee!.pointee.GetStaticDoubleField!(env, clazz.ref, fieldId.id)
    }

    // MARK: - Set Static Fields

    public func setStaticObjectField(_ clazz: JClass, _ fieldId: JFieldId, _ value: JObject?) {
        env.pointee!.pointee.SetStaticObjectField!(env, clazz.ref, fieldId.id, value?.ref)
    }

    public func setStaticBooleanField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jboolean) {
        env.pointee!.pointee.SetStaticBooleanField!(env, clazz.ref, fieldId.id, value)
    }

    public func setStaticByteField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jbyte) {
        env.pointee!.pointee.SetStaticByteField!(env, clazz.ref, fieldId.id, value)
    }

    public func setStaticCharField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jchar) {
        env.pointee!.pointee.SetStaticCharField!(env, clazz.ref, fieldId.id, value)
    }

    public func setStaticShortField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jshort) {
        env.pointee!.pointee.SetStaticShortField!(env, clazz.ref, fieldId.id, value)
    }

    public func setStaticIntField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jint) {
        env.pointee!.pointee.SetStaticIntField!(env, clazz.ref, fieldId.id, value)
    }

    public func setStaticLongField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jlong) {
        env.pointee!.pointee.SetStaticLongField!(env, clazz.ref, fieldId.id, value)
    }

    public func setStaticFloatField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jfloat) {
        env.pointee!.pointee.SetStaticFloatField!(env, clazz.ref, fieldId.id, value)
    }

    public func setStaticDoubleField(_ clazz: JClass, _ fieldId: JFieldId, _ value: jdouble) {
        env.pointee!.pointee.SetStaticDoubleField!(env, clazz.ref, fieldId.id, value)
    }

    // MARK: - Java Strings

    /// Create a new Java UTF-16 string from a buffer of `jchar` values.
    public func newString(chars: UnsafePointer<jchar>, length: jint) -> jstring? {
        env.pointee!.pointee.NewString!(env, chars, length)
    }

    /// Get the UTF-16 length of a Java string.
    public func getStringLength(_ string: jstring) -> Int32 {
        env.pointee!.pointee.GetStringLength!(env, string)
    }

    /// Get a pointer to the UTF-16 contents of a Java string.
    ///
    /// - Important: Must call `releaseStringChars` when done.
    public func getStringChars(_ string: jstring, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafePointer<jchar>? {
        env.pointee!.pointee.GetStringChars!(env, string, isCopy)
    }

    /// Release the pointer returned by `getStringChars`.
    public func releaseStringChars(_ string: jstring, chars: UnsafePointer<jchar>) {
        env.pointee!.pointee.ReleaseStringChars!(env, string, chars)
    }

    /// Create a new Java UTF-8 string from a C string.
    public func newStringUTF(_ string: String) -> jstring? {
        string.withCString {
            env.pointee!.pointee.NewStringUTF!(env, $0)
        }
    }

    /// Get the UTF-8 byte length of a Java string.
    public func getStringUTFLength(_ string: jstring) -> Int32 {
        env.pointee!.pointee.GetStringUTFLength!(env, string)
    }

    /// Get a pointer to the UTF-8 contents of a Java string.
    ///
    /// - Important: Must call `releaseStringUTFChars` when done.
    public func getStringUTFChars(_ string: jstring, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafePointer<CChar>? {
        env.pointee!.pointee.GetStringUTFChars!(env, string, isCopy)
    }

    /// Release the pointer returned by `getStringUTFChars`.
    public func releaseStringUTFChars(_ string: jstring, chars: UnsafePointer<CChar>) {
        env.pointee!.pointee.ReleaseStringUTFChars!(env, string, chars)
    }

    // MARK: - Java Arrays

    /// Get the length of any Java array (including object arrays).
    public func getArrayLength(_ array: jarray) -> Int32 {
        env.pointee!.pointee.GetArrayLength!(env, array)
    }

    // MARK: - Object Arrays

    /// Create a new object array of the given length and element class.
    public func newObjectArray(length: jint, clazz: JClass, initialElement: JObject? = nil) async -> JObjectArray? {
        guard let obj = env.pointee!.pointee.NewObjectArray!(env, length, clazz.ref, initialElement?.ref) else { return nil }
        return await JObjectArray(obj, clazz)
    }

    /// Get an element from an object array.
    public func getObjectArrayElement(_ array: JObjectArray, index: jint) -> JObject? {
        JObject(env.pointee!.pointee.GetObjectArrayElement!(env, array.ref.assumingMemoryBound(to: jobjectArray.self).pointee, index), array.clazz)
    }

    /// Set an element in an object array.
    public func setObjectArrayElement(_ array: JObjectArray, index: jint, value: JObject?) {
        env.pointee!.pointee.SetObjectArrayElement!(env, array.ref, index, value?.ref)
    }

    // MARK: - Primitive Arrays

    public func newBooleanArray(length: jint) -> jbooleanArray? {
        env.pointee!.pointee.NewBooleanArray!(env, length)
    }

    public func newByteArray(length: jint) -> jbyteArray? {
        env.pointee!.pointee.NewByteArray!(env, length)
    }

    public func newCharArray(length: jint) -> jcharArray? {
        env.pointee!.pointee.NewCharArray!(env, length)
    }

    public func newShortArray(length: jint) -> jshortArray? {
        env.pointee!.pointee.NewShortArray!(env, length)
    }

    public func newIntArray(length: jint) -> jintArray? {
        env.pointee!.pointee.NewIntArray!(env, length)
    }

    public func newLongArray(length: jint) -> jlongArray? {
        env.pointee!.pointee.NewLongArray!(env, length)
    }

    public func newFloatArray(length: jint) -> jfloatArray? {
        env.pointee!.pointee.NewFloatArray!(env, length)
    }

    public func newDoubleArray(length: jint) -> jdoubleArray? {
        env.pointee!.pointee.NewDoubleArray!(env, length)
    }

    // MARK: - Get Primitive Array Elements

    /// Get a pointer to the contents of a `boolean[]` array.
    public func getBooleanArrayElements(
        _ array: jbooleanArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jboolean>? {
        env.pointee!.pointee.GetBooleanArrayElements!(env, array, isCopy)
    }

    public func getByteArrayElements(
        _ array: jbyteArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jbyte>? {
        env.pointee!.pointee.GetByteArrayElements!(env, array, isCopy)
    }

    public func getCharArrayElements(
        _ array: jcharArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jchar>? {
        env.pointee!.pointee.GetCharArrayElements!(env, array, isCopy)
    }

    public func getShortArrayElements(
        _ array: jshortArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<jshort>? {
        env.pointee!.pointee.GetShortArrayElements!(env, array, isCopy)
    }

    public func getIntArrayElements(
        _ array: jintArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Int32>? {
        env.pointee!.pointee.GetIntArrayElements!(env, array, isCopy)
    }

    public func getLongArrayElements(
        _ array: jlongArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Int64>? {
        env.pointee!.pointee.GetLongArrayElements!(env, array, isCopy)
    }

    public func getFloatArrayElements(
        _ array: jfloatArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Float>? {
        env.pointee!.pointee.GetFloatArrayElements!(env, array, isCopy)
    }

    public func getDoubleArrayElements(
        _ array: jdoubleArray,
        isCopy: UnsafeMutablePointer<jboolean>? = nil
    ) -> UnsafeMutablePointer<Double>? {
        env.pointee!.pointee.GetDoubleArrayElements!(env, array, isCopy)
    }

    // MARK: - Release Primitive Array Elements

    /// Release the pointer returned by `getBooleanArrayElements`.
    public func releaseBooleanArrayElements(
        _ array: jbooleanArray,
        _ elems: UnsafeMutablePointer<jboolean>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseBooleanArrayElements!(env, array, elems, mode)
    }

    public func releaseByteArrayElements(
        _ array: jbyteArray,
        _ elems: UnsafeMutablePointer<jbyte>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseByteArrayElements!(env, array, elems, mode)
    }

    public func releaseCharArrayElements(
        _ array: jcharArray,
        _ elems: UnsafeMutablePointer<jchar>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseCharArrayElements!(env, array, elems, mode)
    }

    public func releaseShortArrayElements(
        _ array: jshortArray,
        _ elems: UnsafeMutablePointer<jshort>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseShortArrayElements!(env, array, elems, mode)
    }

    public func releaseIntArrayElements(
        _ array: jintArray,
        _ elems: UnsafeMutablePointer<jint>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseIntArrayElements!(env, array, elems, mode)
    }

    public func releaseLongArrayElements(
        _ array: jlongArray,
        _ elems: UnsafeMutablePointer<jlong>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseLongArrayElements!(env, array, elems, mode)
    }

    public func releaseFloatArrayElements(
        _ array: jfloatArray,
        _ elems: UnsafeMutablePointer<jfloat>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseFloatArrayElements!(env, array, elems, mode)
    }

    public func releaseDoubleArrayElements(
        _ array: jdoubleArray,
        _ elems: UnsafeMutablePointer<jdouble>,
        mode: jint = 0
    ) {
        env.pointee!.pointee.ReleaseDoubleArrayElements!(env, array, elems, mode)
    }

    // MARK: - Array Region Getters

    public func getBooleanArrayRegion(_ array: jbooleanArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jboolean>) {
        env.pointee!.pointee.GetBooleanArrayRegion!(env, array, start, length, buffer)
    }

    public func getByteArrayRegion(_ array: jbyteArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jbyte>) {
        env.pointee!.pointee.GetByteArrayRegion!(env, array, start, length, buffer)
    }

    public func getCharArrayRegion(_ array: jcharArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jchar>) {
        env.pointee!.pointee.GetCharArrayRegion!(env, array, start, length, buffer)
    }

    public func getShortArrayRegion(_ array: jshortArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jshort>) {
        env.pointee!.pointee.GetShortArrayRegion!(env, array, start, length, buffer)
    }

    public func getIntArrayRegion(_ array: jintArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jint>) {
        env.pointee!.pointee.GetIntArrayRegion!(env, array, start, length, buffer)
    }

    public func getLongArrayRegion(_ array: jlongArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jlong>) {
        env.pointee!.pointee.GetLongArrayRegion!(env, array, start, length, buffer)
    }

    public func getFloatArrayRegion(_ array: jfloatArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jfloat>) {
        env.pointee!.pointee.GetFloatArrayRegion!(env, array, start, length, buffer)
    }

    public func getDoubleArrayRegion(_ array: jdoubleArray, start: jint, length: jint, buffer: UnsafeMutablePointer<jdouble>) {
        env.pointee!.pointee.GetDoubleArrayRegion!(env, array, start, length, buffer)
    }

    // MARK: - Array Region Setters

    public func setBooleanArrayRegion(_ array: jbooleanArray, start: jint, length: jint, buffer: UnsafePointer<jboolean>) {
        env.pointee!.pointee.SetBooleanArrayRegion!(env, array, start, length, buffer)
    }

    public func setByteArrayRegion(_ array: jbyteArray, start: jint, length: jint, buffer: UnsafePointer<jbyte>) {
        env.pointee!.pointee.SetByteArrayRegion!(env, array, start, length, buffer)
    }

    public func setCharArrayRegion(_ array: jcharArray, start: jint, length: jint, buffer: UnsafePointer<jchar>) {
        env.pointee!.pointee.SetCharArrayRegion!(env, array, start, length, buffer)
    }

    public func setShortArrayRegion(_ array: jshortArray, start: jint, length: jint, buffer: UnsafePointer<jshort>) {
        env.pointee!.pointee.SetShortArrayRegion!(env, array, start, length, buffer)
    }

    public func setIntArrayRegion(_ array: jintArray, start: jint, length: jint, buffer: UnsafePointer<jint>) {
        env.pointee!.pointee.SetIntArrayRegion!(env, array, start, length, buffer)
    }

    public func setLongArrayRegion(_ array: jlongArray, start: jint, length: jint, buffer: UnsafePointer<jlong>) {
        env.pointee!.pointee.SetLongArrayRegion!(env, array, start, length, buffer)
    }

    public func setFloatArrayRegion(_ array: jfloatArray, start: jint, length: jint, buffer: UnsafePointer<jfloat>) {
        env.pointee!.pointee.SetFloatArrayRegion!(env, array, start, length, buffer)
    }

    public func setDoubleArrayRegion(_ array: jdoubleArray, start: jint, length: jint, buffer: UnsafePointer<jdouble>) {
        env.pointee!.pointee.SetDoubleArrayRegion!(env, array, start, length, buffer)
    }

    // MARK: - Native Method Registration

    public func registerNatives(clazz: JClass, methods: UnsafePointer<JNINativeMethod>, count: jint) -> Int32 {
        env.pointee!.pointee.RegisterNatives!(env, clazz.ref, methods, count)
    }

    public func unregisterNatives(clazz: JClass) -> Int32 {
        env.pointee!.pointee.UnregisterNatives!(env, clazz.ref)
    }

    // MARK: - Monitor (synchronized) Helpers

    public func monitorEnter(_ object: JObject) -> Int32 {
        env.pointee!.pointee.MonitorEnter!(env, object.ref)
    }

    public func monitorExit(_ object: JObject) -> Int32 {
        env.pointee!.pointee.MonitorExit!(env, object.ref)
    }

    // MARK: - JVM Access

    public func getJavaVM() -> UnsafeMutablePointer<JavaVM?>? {
        var vm: UnsafeMutablePointer<JavaVM?>?
        _ = env.pointee!.pointee.GetJavaVM!(env, &vm)
        return vm
    }

    // MARK: - String Region Access

    public func getStringRegion(_ string: jstring, start: jint, length: jint, buffer: UnsafeMutablePointer<jchar>) {
        env.pointee!.pointee.GetStringRegion!(env, string, start, length, buffer)
    }

    public func getStringUTFRegion(_ string: jstring, start: jint, length: jint, buffer: UnsafeMutablePointer<CChar>) {
        env.pointee!.pointee.GetStringUTFRegion!(env, string, start, length, buffer)
    }

    // MARK: - Critical Array Access

    public func getPrimitiveArrayCritical(_ array: jarray, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafeMutableRawPointer? {
        env.pointee!.pointee.GetPrimitiveArrayCritical!(env, array, isCopy)
    }

    public func releasePrimitiveArrayCritical(_ array: jarray, pointer: UnsafeMutableRawPointer, mode: jint = 0) {
        env.pointee!.pointee.ReleasePrimitiveArrayCritical!(env, array, pointer, mode)
    }

    // MARK: - Critical String Access

    public func getStringCritical(_ string: jstring, isCopy: UnsafeMutablePointer<jboolean>? = nil) -> UnsafePointer<jchar>? {
        env.pointee!.pointee.GetStringCritical!(env, string, isCopy)
    }

    public func releaseStringCritical(_ string: jstring, chars: UnsafePointer<jchar>) {
        env.pointee!.pointee.ReleaseStringCritical!(env, string, chars)
    }

    // MARK: - Weak Global Refs

    public func newWeakGlobalRef(_ obj: JObject) -> jweak? {
        env.pointee!.pointee.NewWeakGlobalRef!(env, obj.ref)
    }

    public func deleteWeakGlobalRef(_ ref: jweak) {
        env.pointee!.pointee.DeleteWeakGlobalRef!(env, ref)
    }

    // MARK: - Exception Check

    public func exceptionCheck() -> Bool {
        env.pointee!.pointee.ExceptionCheck!(env).value
    }

    // MARK: - Direct ByteBuffer

    public func newDirectByteBuffer(address: UnsafeMutableRawPointer, capacity: Int64) -> jobject? {
        env.pointee!.pointee.NewDirectByteBuffer!(env, address, capacity)
    }

    public func getDirectBufferAddress(_ buffer: JObject) -> UnsafeMutableRawPointer? {
        env.pointee!.pointee.GetDirectBufferAddress!(env, buffer.ref)
    }

    public func getDirectBufferCapacity(_ buffer: JObject) -> Int64 {
        env.pointee!.pointee.GetDirectBufferCapacity!(env, buffer.ref)
    }

    // MARK: - Reference Type Inspection

    public func getObjectRefType(_ obj: JObject) -> JObjectRefType {
        JObjectRefType(env.pointee!.pointee.GetObjectRefType!(env, obj.ref))
    }
}
