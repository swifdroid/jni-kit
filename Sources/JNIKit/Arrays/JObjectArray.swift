//
//  JObjectArray.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android
#endif

/// A Swift wrapper for a Java object array (`jobjectArray`).
///
/// Retains a global reference and provides access to individual `JObject`s.
public struct JObjectArray: Sendable, JObjectable {
    public let object: JObject
    public let length: Int

    public init (_ object: JObject, length: Int) {
        self.object = object
        self.length = length
    }

    public init (_ env: JEnv, _ object: JObject) {
        self.object = object
        #if os(Android)
        self.length = Int(env.getArrayLength(object.ref.ref))
        #else
        self.length = 0
        #endif
    }

    /// Create a new array of Java objects with given size and element class.
    public init? (length: Int, clazz: JClass) {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let array = env.newObjectArray(length: Int32(length), clazz: clazz),
            let global = env.newGlobalRef(JObject(array.ref, clazz))
        else { return nil }
        self.object = JObject(global.ref, clazz)
        self.length = length
        #else
        return nil
        #endif
    }

    /// Create a new array of Java objects with given elements and element class.
    public init? (_ objects: [JObject], clazz: JClass) {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let array = env.newObjectArray(length: Int32(objects.count), clazz: clazz),
            let global = env.newGlobalRef(JObject(array.ref, clazz))
        else { return nil }
        self.object = JObject(global.ref, clazz)
        self.length = objects.count
        for (index, object) in objects.enumerated() {
            self.set(object, at: index)
        }
        #else
        return nil
        #endif
    }

    #if os(Android)
    /// Create a wrapper from an existing `jobjectArray`.
    public init?(_ array: jobjectArray, _ clazz: JClass) {
        guard
            let env = JEnv.current(),
            let box = array.box(env),
            let global = env.newGlobalRef(JObject(box, clazz))
        else { return nil }
        self.object = global
        self.length = Int(env.getArrayLength(global.ref.ref))
    }

    /// Get the object at a given index.
    public func get(at index: Int) -> JObject? {
        guard
            let env = JEnv.current(),
            let obj = env.getObjectArrayElement(self, index: Int32(index))
        else { return nil }
        return obj
    }

    /// Set an object at a given index.
    public func set(_ value: JObject, at index: Int) {
        guard let env = JEnv.current() else { return }
        env.setObjectArrayElement(self, index: Int32(index), value: value)
    }
    #endif
    
    /// Convert to `[JObject]`
    public func toArray() -> [JObject] {
        var result: [JObject] = []
        #if os(Android)
        for i in 0 ..< length {
            if let item = `get`(at: i) {
                result.append(item)
            }
        }
        #endif
        return result
    }
}

extension Array where Element: JObjectable {
    /// Convert to `JObjectArray` with a given `JClass`.
    public func javaArray(of clazz: JClass) -> JObjectArray? {
        JObjectArray(self.map { $0.object }, clazz: clazz)
    }

    /// Convert to `JObjectArray` with a given class name.
    public func javaArray(of className: JClassName) -> JObjectArray? {
        guard let clazz = JClass.load(className) else { return nil }
        return JObjectArray(self.map { $0.object }, clazz: clazz)
    }
}