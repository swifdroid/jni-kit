//
//  JavaArrayable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 25.09.2025.
//

#if os(Android)
import Android
#endif
#if JNILOGS
#if canImport(Logging)
import Logging
#endif
#endif

// MARK: - 1D Array

/// A protocol for 1-dimensional Java array interoperability.
/// Provides unified interface for creating, accessing, and converting Java primitive arrays.
public protocol Java1DArrayable: JObjectable, JValuable, Sequence {
    associatedtype ElementType

    var object: JObject { get }
    var length: Int { get }

    #if os(Android)
    var jValue: jvalue { get }
    #endif

    init (_ object: JObject, length: Int)

    #if os(Android)
    /// Creates a new Java array object of specified length.
    static func newArrayObject(_ env: JEnv, _ length: Int) -> jobject?
    #endif
    /// Copies Swift collection elements into a Java array region.
    static func setArrayRegion<C: ToJavaArrayIterable>(_ env: JEnv, _ object: JObject, _ collection: C) where C.Element == ElementType
    /// Retrieves a single element from Java array at specified index.
    static func getElementAtIndex(_ index: Int, _ object: JObject) -> ElementType?
    /// Copies all elements from Java array to Swift array.
    static func getAllElements(_ env: JEnv, _ object: JObject, _ length: Int) -> [ElementType]
}

extension Java1DArrayable {
    #if os(Android)
    public var jValue: jvalue { .init(l: object.ref.ref) }
    #endif

    /// Creates wrapper from existing JObject with automatic length detection.
    public init (_ env: JEnv, _ object: JObject) {
        #if os(Android)
        self.init(object, length: Int(env.getArrayLength(object.ref.ref)))
        #else
        self.init(object, length: 0)
        #endif
    }

    /// Creates a new Java array of specified length.
    public init? (length: Int) {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let ref = Self.newArrayObject(env, length),
            let global = ref.box(env)?.object()
        else { return nil }
        self.init(global, length: length)
        #else
        return nil
        #endif
    }

    /// Creates a Java array from Swift collection.
    public init? <C: ToJavaArrayIterable> (_ collection: C) where C.Element == ElementType {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let ref = Self.newArrayObject(env, collection.count),
            let global = ref.box(env)?.object()
        else { return nil }
        self.init(global, length: collection.count)
        Self.setArrayRegion(env, object, collection)
        #else
        return nil
        #endif
    }

    #if os(Android)
    /// Creates wrapper from existing `jobject` reference.
    public init?(_ array: jobject) {
        guard
            let env = JEnv.current(),
            let box = array.box(env),
            let global = box.object()
        else { return nil }
        self.init(global, length: Int(env.getArrayLength(global.ref.ref)))
    }
    #endif
    
    /// Converts Java array to Swift array.
    public func toArray() -> [ElementType] {
        #if os(Android)
        guard let env = JEnv.current() else { return [] }
        let length = env.getArrayLength(object.ref.ref)
        return Self.getAllElements(env, object, Int(length))
        #else
        return []
        #endif
    }

    /// Provides sequential access to array elements.
    public func makeIterator() -> AnyIterator<ElementType> {
        #if os(Android)
        let length = Int(JEnv.current()!.getArrayLength(object.ref.ref))
        var index = 0
        return AnyIterator {
            guard index < length else { return nil }
            defer { index += 1 }
            return Self.getElementAtIndex(index, object)
        }
        #else
        return AnyIterator { return nil }
        #endif
    }
}

// MARK: - 2D Array

/// A protocol for 2-dimensional Java array interoperability.
/// Provides unified interface for creating, accessing, and converting Java object arrays.
public protocol Java2DArrayable: JObjectable, JValuable, Sequence {
    associatedtype ElementType

    var object: JObject { get }
    var length: Int { get }

    #if os(Android)
    var jValue: jvalue { get }
    #endif

    /// Java class name for array elements (e.g., "[I" for int[])
    static var elementClass: JClassName { get }
    var elementClazz: JClass? { get }

    init (_ object: JObject, length: Int)

    /// Converts Swift collection to Java array object.
    static func javaArrayFromCollection<C: ToJavaArrayIterable>(_ collection: C) -> JObject? where C.Element == ElementType
    /// Converts Java array object to Swift array.
    static func arrayFromJavaArray(_ env: JEnv, _ obj: JObject) -> [ElementType]?
}

extension Java2DArrayable {
    #if os(Android)
    public var jValue: jvalue { .init(l: object.ref.ref) }
    #endif

    public var elementClazz: JClass? { JClass.load(Self.elementClass) }

    /// Creates wrapper from existing JObject with automatic length detection.
    public init (_ env: JEnv, _ object: JObject) {
        #if os(Android)
        self.init(object, length: Int(env.getArrayLength(object.ref.ref)))
        #else
        self.init(object, length: 0)
        #endif
    }

    /// Creates a new Java object array of specified length.
    public init? (length: Int) {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let clazz = JClass.load(Self.elementClass),
            let global = env.newObjectArray(length: Int32(length), clazz: clazz)
        else { return nil }
        self.init(global.object, length: length)
        #else
        return nil
        #endif
    }

    /// Creates a Java 2D array from Swift collection of arrays.
    public init? <C: ToJavaArrayIterable> (_ collection: C) where C.Element == [ElementType] {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let clazz = JClass.load(Self.elementClass),
            let global = env.newObjectArray(length: Int32(collection.count), clazz: clazz)
        else { return nil }
        self.init(global.object, length: collection.count)
        for item in collection.makeIterator().enumerated() {
            set(item.element, at: item.offset)
        }
        #else
        return nil
        #endif
    }

    /// Sets Java object at specified index in the array.
    public func set(_ value: JObject, at index: Int) {
        #if os(Android)
        guard let env = JEnv.current() else { return }
        env.setObjectArrayElement(.init(object, length: length), index: Int32(index), value: value)
        #endif
    }

    /// Sets Java array at specified index from Swift collection.
    public func set<C: ToJavaArrayIterable>(_ collection: C, at index: Int) where C.Element == ElementType {
        #if os(Android)
        guard let env = JEnv.current() else { return }
        guard let arr = Self.javaArrayFromCollection(collection) else { return }
        env.setObjectArrayElement(object, index: Int32(index), value: arr)
        #endif
    }

    /// Retrieves Java object at specified index.
    public func getObject(at index: Int) -> JObject? {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let obj = env.getObjectArrayElement(object, index: Int32(index), returningClass: elementClazz)
        else { return nil }
        return obj
        #else
        return nil
        #endif
    }
    
    /// Retrieves Swift array at specified index.
    public func getArray(at index: Int) -> [ElementType]? {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let obj = env.getObjectArrayElement(object, index: Int32(index), returningClass: elementClazz)
        else { return nil }
        return Self.arrayFromJavaArray(env, obj)
        #else
        return nil
        #endif
    }
    
    /// Converts Java 2D array to Swift 2D array.
    /// 
    /// ⚠️ Be carefuls with large arrays, this may consume a lot of memory.
    public func toArray() -> [[ElementType]] {
        var result: [[ElementType]] = []
        #if os(Android)
        guard let env = JEnv.current() else { return result }
        let length = env.getArrayLength(object.ref.ref)
        // Get array elements
        for i in 0..<length {
            if let arr = getArray(at: Int(i)) {
                result.append(arr)
            } else {
                #if JNILOGS
                Logger.critical("⚠️ \(Self.self).toArray failed to get array at index \(i), appended empty array instead")
                #endif
                result.append([])
            }
        }
        #endif
        return result
    }

    /// Provides sequential access to array elements.
    public func makeIterator() -> AnyIterator<[ElementType]> {
        #if os(Android)
        let length = Int(JEnv.current()!.getArrayLength(object.ref.ref))
        var index = 0
        return AnyIterator {
            guard index < length else { return nil }
            defer { index += 1 }
            return self.getArray(at: Int(index))!
        }
        #else
        return AnyIterator { return nil }
        #endif
    }
}