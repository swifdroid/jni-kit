//
//  JBoolArray.swift
//  JNIKit
//
//  Created by Mihael Isaev on 25.09.2025.
//

#if os(Android)
import Android
#endif

/// A Swift wrapper for a Java boolean array (`jbooleanArray`).
///
/// Retains a global reference and provides access to individual `jboolean`s.
public final class JBoolArray: Java1DArrayable {
    public typealias ElementType = Bool
    
    public let object: JObject
    public let length: Int

    public init (_ object: JObject, length: Int) {
        self.object = object
        self.length = length
    }

    #if os(Android)
    public static func newArrayObject(_ env: JEnv, _ length: Int) -> jobject? {
        env.newBooleanArray(length: Int32(length))
    }
    #endif

    public static func setArrayRegion<C>(_ env: JEnv, _ object: JObject, _ collection: C) where C : ToJavaArrayIterable, ElementType == C.Element {
        #if os(Android)
        var cArray: [UInt8] = collection.array?.map { UInt8($0 ? 1 : 0) } ?? collection.makeIterator().map { UInt8($0 ? 1 : 0) }
        env.setBooleanArrayRegion(object.ref.ref, start: 0, length: jsize(collection.count), buffer: &cArray)
        #endif
    }

    public static func getElementAtIndex(_ index: Int, _ object: JObject) -> ElementType? {
        #if os(Android)
        guard let env = JEnv.current() else { return nil }
        var result: UInt8 = 0
        env.getBooleanArrayRegion(object.ref.ref, start: jsize(index), length: 1, buffer: &result)
        return result != 0
        #else
        return nil
        #endif
    }

    public static func getAllElements(_ env: JEnv, _ object: JObject, _ length: Int) -> [ElementType] {
        #if os(Android)
        var result = [UInt8](repeating: 0, count: Int(length))
        env.getBooleanArrayRegion(object.ref.ref, start: 0, length: Int32(length), buffer: &result)
        return result.map { $0 != 0}
        #else
        return []
        #endif
    }
}

public final class JBoolArray2D: Java2DArrayable {
    public typealias ElementType = Bool

    public let object: JObject
    public let length: Int

    public static var elementClass: JClassName { "[Z" }

    public init (_ object: JObject, length: Int) {
        self.object = object
        self.length = length
    }

    public static func javaArrayFromCollection<C: ToJavaArrayIterable>(_ collection: C) -> JObject? where C.Element == ElementType {
        JBoolArray(collection)?.object
    }

    public static func arrayFromJavaArray(_ env: JEnv, _ obj: JObject) -> [ElementType]? {
        JBoolArray(env, obj).toArray()
    }
}