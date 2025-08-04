//
//  JClassLoadable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 07.07.2025.
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
/// let classLoader = myObject.getClassLoader()
/// ```
public protocol JClassLoadable: AnyObject, Sendable {
    /// The underlying JNI reference to the Java object.
    var ref: JObjectBox { get }
    
    /// The resolved `JClass` associated with the object’s declared type.
    var clazz: JClass { get }

    /// Returns the result of calling Java’s `getClass()` method on this object.
    ///
    /// - Returns: A `JObject` representing a Java `Class` instance, or `nil` if lookup or call fails.
    func getClassLoader() -> JClassLoader?
}
import Logging
extension JClassLoadable {
    /// Default implementation of `getClass()` using JNI.
    ///
    /// - Retrieves the `getClass` method ID from the object's `clazz`.
    /// - Calls the method with no arguments on the current instance.
    ///
    /// - Returns: A `JObject` representing the Java class instance (`java.lang.Class`),
    ///   or `nil` if the call fails.
    public func getClassLoader() -> JClassLoader? {
        #if os(Android)
        guard
            let env = JEnv.current() else {
                // logger?.info("getClassLoader 1 exit")
                return nil
            }
            guard let clazz = env.findClass("java/lang/ClassLoader") else {
                // logger?.info("getClassLoader 2 exit")
                return nil
            }
            guard let methodId = self.clazz.methodId(
                env: env,
                name: "getClassLoader",
                signature: .returning("java/lang/ClassLoader")
            ) else {
                // logger?.info("getClassLoader 3 exit")
                return nil
            }
        guard let obj = env.callObjectMethod(object: .init(ref, self.clazz), methodId: methodId, clazz: clazz, args: [])
        else {
            // logger?.info("getClassLoader 4 exit")
            return nil
        }
        return JClassLoader(obj)
        #else
        return nil
        #endif
    }
}
