//
//  JDoubleArray.swift
//  JNIKit
//
//  Created by Mihael Isaev on 25.09.2025.
//

#if os(Android)
import Android
#endif

/// A Swift wrapper for a Java double array (`jdoubleArray`).
///
/// Retains a global reference and provides access to individual `jdouble`s.
public final class JDoubleArray: Java1DArrayable {
    public typealias ElementType = Double

    public static let className: JClassName = "[D"

    public let object: JObject
    public let length: Int

    public init (_ object: JObject, length: Int) {
        self.object = object
        self.length = length
    }

    #if os(Android)
    public static func newArrayObject(_ env: JEnv, _ length: Int) -> jobject? {
        env.newDoubleArray(length: Int32(length))
    }
    #endif

    public static func setArrayRegion<C>(_ env: JEnv, _ object: JObject, _ collection: C) where C : ToJavaArrayIterable, ElementType == C.Element {
        #if os(Android)
        var cArray: [ElementType] = collection.array ?? collection.makeIterator().map { $0 }
        env.setDoubleArrayRegion(object.ref.ref, start: 0, length: jsize(collection.count), buffer: &cArray)
        #endif
    }

    public static func getElementAtIndex(_ index: Int, _ object: JObject) -> ElementType? {
        #if os(Android)
        guard let env = JEnv.current() else { return nil }
        var result: ElementType = 0
        env.getDoubleArrayRegion(object.ref.ref, start: jsize(index), length: 1, buffer: &result)
        return result
        #else
        return nil
        #endif
    }

    public static func getAllElements(_ env: JEnv, _ object: JObject, _ length: Int) -> [ElementType] {
        #if os(Android)
        var result = [ElementType](repeating: 0, count: length)
        env.getDoubleArrayRegion(object.ref.ref, start: 0, length: Int32(length), buffer: &result)
        return result
        #else
        return []
        #endif
    }
}

public final class JDoubleArray2D: Java2DArrayable {
    public typealias ElementType = Double

    public let object: JObject
    public let length: Int

    public static var elementClass: JClassName { "[D" }

    public init (_ object: JObject, length: Int) {
        self.object = object
        self.length = length
    }

    public static func javaArrayFromCollection<C: ToJavaArrayIterable>(_ collection: C) -> JObject? where C.Element == ElementType {
        JDoubleArray(collection)?.object
    }

    public static func arrayFromJavaArray(_ env: JEnv, _ obj: JObject) -> [ElementType]? {
        JDoubleArray(env, obj).toArray()
    }
}