//
//  JStringable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android
#endif

/// A protocol for Java objects that can provide a Swift-readable string via Java's `toString()` method.
///
/// This protocol is useful for working with any Java object that overrides `toString()` for meaningful output,
/// such as instances of `java.lang.Object`, `java.lang.Throwable`, or custom classes.
///
/// You can conform types like `JObject`, `JThrowable`, or `JString` to this protocol to make them
/// printable or loggable directly from Swift.
///
/// Example:
/// ```swift
/// struct MyJavaObject: JStringable {
///     let ref: jobject
///     let clazz: JClass
///
///     // Now you can call `myObject.toString()` to get its string representation
/// }
/// ```
public protocol JStringable: Sendable {
    /// The raw JNI object reference representing this Java object.
    var ref: JObjectBox { get }
    
    /// The resolved Java class of this object, used to look up method references like `toString()`.
    var clazz: JClass { get }

    /// Calls the Java `toString()` method and returns the result as a Swift `String`.
    ///
    /// This method performs a JNI call to `toString()` on the wrapped object, converts the resulting `jstring`
    /// into a Swift `String`, and automatically releases memory when done.
    ///
    /// - Returns: The result of `toString()` as a Swift string, or `nil` if the call fails.
    func toString() -> String
}

extension JStringable {
    /// Default implementation of `toString()` for any type conforming to `JStringable`.
    ///
    /// Internally, this:
    /// 1. Attaches the current thread to the JVM if needed.
    /// 2. Retrieves the `toString()` method ID from the object's class.
    /// 3. Calls `toString()` via JNI on the underlying `jobject`.
    /// 4. Converts the resulting Java `jstring` into a Swift `String`.
    ///
    /// - Returns: A Swift `String` representation of the Java object, or `nil` if the method could not be invoked.
    public func toString() -> String {
        #if os(Android)
        let fallbackResult = "\(clazz.name.fullName)@\(ref)"
        let object = JObject(ref, clazz)
        guard
            let env = JEnv.current(),
            let clazz = env.findClass("java/lang/String"),
            let jstr = object.callObjectMethod(name: "toString", returningClass: clazz, returning: .object(clazz.name))            
        else { return fallbackResult }
        return JString(from: jstr.ref.ref)?.toSwiftString() ?? fallbackResult
        #else
        return ""
        #endif
    }
}
