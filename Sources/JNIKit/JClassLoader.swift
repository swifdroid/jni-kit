//
//  JClassLoader.swift
//  JNIKit
//
//  Created by Mihael Isaev on 07.07.2025.
//

#if os(Android)
import Android
#endif
#if JNILOGS
#if canImport(Logging)
import Logging
#endif
#endif

/// A Swift wrapper around a Java `ClassLoader` object.
///
/// A class loader is an object that is responsible for loading classes. 
public final class JClassLoader: Sendable, JObjectable {
    /// The JNI class name for `dalvik.system.PathClassLoader`.
    public static let className: JClassName = "java/lang/ClassLoader"

    /// Object wrapper
    public let object: JObject

    // MARK: - Initializers

    init? (_ object: JObject) {
        self.object = object
    }
}

// MARK: - Instance Methods

extension JClassLoader {
    /// Loads the class with the specified binary name.
    ///
    /// - Parameter name: JNI slash-separated class path (e.g. `"java/lang/String"`)
    /// - Returns: A wrapped class reference or `nil` if not found.
    public func loadClass(_ name: JClassName) -> JClass? {
        #if os(Android)
        #if JNILOGS
        Logger.trace("JClassLoader.loadClass 1 clazz: \(clazz.name.path)")
        #endif
        guard
            let env = JEnv.current() else {
                #if JNILOGS
                Logger.info("JClassLoader.loadClass 1 exit")
                #endif
                return nil
            }
        #if JNILOGS
        Logger.info("JClassLoader.loadClass 2")
        #endif
            guard let methodId = clazz.methodId(env: env, name: "loadClass", signature: .init(.object(.init(stringLiteral: "java/lang/String")), returning: .object(.init(stringLiteral: "java/lang/Class"))))
        else {
            #if JNILOGS
            Logger.info("JClassLoader.loadClass 2 exit")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.info("JClassLoader.loadClass 3")
        #endif
        guard let className = JString(from: name.path) else {
            #if JNILOGS
            Logger.info("JClassLoader.findClass 3 exit")
            #endif
            return nil
        }
        #if JNILOGS
        Logger.info("JClassLoader.loadClass 4")
        #endif
        guard
            let local = env.callObjectMethodPure(ref: ref.ref, methodId: methodId, args: [className])
        else {
            #if JNILOGS
            Logger.info("JClassLoader.findClass 4 exit")
            #endif
            return nil
        }
        defer {
            env.deleteLocalRefPure(local)
        }
        let globalRef = env.newGlobalRefPure(local)
        #if JNILOGS
        Logger.info("JClassLoader.loadClass 5 globalRef: \(globalRef)")
        #endif
        return JClass(globalRef, name)
        #else
        return nil
        #endif
    }

    // /// Finds a class by name using this class loader.
    // ///
    // /// - Parameter name: JNI slash-separated class path (e.g. `"java/lang/String"`)
    // /// - Returns: A wrapped class reference or `nil` if not found.
    // public func findClass(_ name: JClassName, _ logger: Logger? = nil) -> JClass? {
    //     logger?.info("classLoader.findClass 1 clazz: \(clazz.name.path)")
    //     guard
    //         let env = JEnv.current() else {
    //             logger?.info("classLoader.findClass 1 exit")
    //             return nil
    //         }
    //         guard let methodId = clazz.methodId(env: env, name: "findClass", signature: .init(.object("java/lang/String"), returning: .object("java/lang/Class")))
    //     else {
    //         logger?.info("classLoader.findClass 2 exit");return nil
    //         }
    //     guard
    //         let classObject = env.callObjectMethod(object: .init(ref, clazz), methodId: methodId, args: [])
    //     else { logger?.info("classLoader.findClass 3 exit");return nil }
    //     return JClass(classObject.ref, name)
    // }
}
