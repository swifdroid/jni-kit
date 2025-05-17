//
//  JObjectArray.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

/// A Swift wrapper for a Java object array (`jobjectArray`).
///
/// Retains a global reference and provides access to individual `JObject`s.
public struct JObjectArray: @unchecked Sendable, JavaDescribable {
    public let ref: jobject // jobjectArray
    public let clazz: JClass
    public let length: Int

    /// Create a new array of Java objects with given size and element class.
    public init?(length: Int, clazz: JClass) async {
        guard
            let env = await JEnv.current(),
            let array = await env.newObjectArray(length: Int32(length), clazz: clazz),
            let global = env.newGlobalRef(JObject(array.ref, clazz))
        else { return nil }
        self.ref = global.ref
        self.clazz = clazz
        self.length = length
    }

    /// Create a wrapper from an existing `jobjectArray`.
    public init?(_ array: jobjectArray, _ clazz: JClass) async {
        guard
            let env = await JEnv.current(),
            let global = env.newGlobalRef(JObject(array, clazz))
        else { return nil }
        self.ref = global.ref
        self.clazz = clazz
        self.length = Int(env.getArrayLength(global.ref))
    }

    /// Get the object at a given index.
    public func get(at index: Int) async -> JObject? {
        guard
            let env = await JEnv.current(),
            let obj = env.getObjectArrayElement(self, index: Int32(index))
        else { return nil }
        return JObject(obj.ref, clazz)
    }

    /// Set an object at a given index.
    public func set(_ value: JObject, at index: Int) async {
        guard let env = await JEnv.current() else { return }
        let jArray = value.ref.assumingMemoryBound(to: jobjectArray.self)
        let clazz = JClass(value.clazz.ref, value.className)
        guard let jObjectArray = await JObjectArray(jArray, clazz) else { return }
        env.setObjectArrayElement(jObjectArray, index: Int32(index), value: value)
    }

    /// Convert to `[JObject]`
    public func toArray() async -> [JObject] {
        var result: [JObject] = []
        for i in 0..<length {
            if let item = await get(at: i) {
                result.append(item)
            }
        }
        return result
    }
}
