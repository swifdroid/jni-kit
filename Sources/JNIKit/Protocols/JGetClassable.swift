//
//  JGetClassable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 18.05.2025.
//

#if os(Android)
import Android
#endif

/// A protocol for Java objects that expose the `getClass()` method to retrieve their runtime type.
///
/// This mirrors Java’s `Object.getClass()` method, which returns a `Class` object representing
/// the runtime class of the instance. This is especially useful for type reflection,
/// dynamic type checking, or introspection.
///
/// All Java objects inherit this method from `java.lang.Object`.
///
/// Example usage:
/// ```swift
/// if let clazz = myObject.getClass() {
///     print("Runtime Java class object: \(clazz)")
/// }
/// ```
public protocol JGetClassable: Sendable {
    #if os(Android)
    /// The underlying JNI reference to the Java object.
    var ref: jobject { get }
    #endif

    /// The resolved `JClass` associated with the object’s declared type.
    var clazz: JClass { get }

    /// Returns the result of calling Java’s `getClass()` method on this object.
    ///
    /// - Returns: A `JObject` representing a Java `Class` instance, or `nil` if lookup or call fails.
    func getClass() -> JObject?
}

extension JGetClassable {
    /// Default implementation of `getClass()` using JNI.
    ///
    /// - Retrieves the `getClass` method ID from the object's `clazz`.
    /// - Calls the method with no arguments on the current instance.
    ///
    /// - Returns: A `JObject` representing the Java class instance (`java.lang.Class`),
    ///   or `nil` if the call fails.
    public func getClass() -> JObject? {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(
                name: "getClass",
                signature: .returning("java/lang/Class")
            )
        else { return nil }
        return env.callObjectMethod(object: .init(ref, clazz), methodId: methodId, args: [])
        #else
        return nil
        #endif
    }
}
