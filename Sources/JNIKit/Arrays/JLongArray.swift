//
//  JLongArray.swift
//  JNIKit
//
//  Created by Mihael Isaev on 25.09.2025.
//

#if os(Android)
import Android
#endif

public typealias JLongArray = JInt64Array

/// A Swift wrapper for a Java long array (`jlongArray`).
///
/// Retains a global reference and provides access to individual `jlong`s.
public final class JInt64Array: Java1DArrayable {
    public typealias ElementType = Int64

    public let object: JObject
    public let length: Int

    public init (_ object: JObject, length: Int) {
        self.object = object
        self.length = length
    }

    #if os(Android)
    public static func newArrayObject(_ env: JEnv, _ length: Int) -> jobject? {
        env.newLongArray(length: Int32(length))
    }
    #endif

    public static func setArrayRegion<C>(_ env: JEnv, _ object: JObject, _ collection: C) where C : ToJavaArrayIterable, ElementType == C.Element {
        #if os(Android)
        var cArray: [ElementType] = collection.array ?? collection.makeIterator().map { $0 }
        env.setLongArrayRegion(object.ref.ref, start: 0, length: jsize(collection.count), buffer: &cArray)
        #endif
    }

    public static func getElementAtIndex(_ index: Int, _ object: JObject) -> ElementType? {
        #if os(Android)
        guard let env = JEnv.current() else { return nil }
        var result: ElementType = 0
        env.getLongArrayRegion(object.ref.ref, start: jsize(index), length: 1, buffer: &result)
        return result
        #else
        return nil
        #endif
    }

    public static func getAllElements(_ env: JEnv, _ object: JObject, _ length: Int) -> [ElementType] {
        #if os(Android)
        var result = [ElementType](repeating: 0, count: length)
        env.getLongArrayRegion(object.ref.ref, start: 0, length: Int32(length), buffer: &result)
        return result
        #else
        return []
        #endif
    }
}

public typealias JLongArray2D = JInt64Array2D

public final class JInt64Array2D: Java2DArrayable {
    public typealias ElementType = Int64

    public let object: JObject
    public let length: Int

    public static var elementClass: JClassName { "[J" }

    public init (_ object: JObject, length: Int) {
        self.object = object
        self.length = length
    }

    public static func javaArrayFromCollection<C: ToJavaArrayIterable>(_ collection: C) -> JObject? where C.Element == ElementType {
        JInt64Array(collection)?.object
    }

    public static func arrayFromJavaArray(_ env: JEnv, _ obj: JObject) -> [ElementType]? {
        JInt64Array(env, obj).toArray()
    }
}