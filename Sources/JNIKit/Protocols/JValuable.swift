//
//  JValuable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if os(Android)
import Android
#endif

/// A protocol that allows Swift types to be converted into a JNI-compatible `jvalue`
///
/// Conforming types can be passed directly into JNI method calls through convenience APIs.
/// For example: `callMethod(name: "add", args: [1, 2.0, true])`
public protocol JValuable {
    #if os(Android)
    /// Convert the Swift value into a JNI `jvalue` union
    var jValue: jvalue { get }
    #endif
}

/// Represents a Java null reference
public struct JNull {
    public init() {}
}

#if os(Android)
extension JNull: JValuable {
    public var jValue: jvalue {
        return jvalue(l: nil)
    }
}

extension Int: JValuable {
    /// Converts `Int` to JNI `jint`
    public var jValue: jvalue { .init(i: jint(self)) }
}

extension Int8: JValuable {
    /// Converts `Int8` to JNI `jbyte`
    public var jValue: jvalue { .init(b: jbyte(self)) }
}

extension Int16: JValuable {
    /// Converts `Int16` to JNI `jshort`
    public var jValue: jvalue { .init(s: jshort(self)) }
}

extension Int32: JValuable {
    /// Converts `Int32` to JNI `jint`
    public var jValue: jvalue { .init(i: jint(self)) }
}

extension Int64: JValuable {
    /// Converts `Int64` to JNI `jlong`
    public var jValue: jvalue { .init(j: jlong(self)) }
}

extension Bool: JValuable {
    /// Converts `Bool` to JNI `jboolean` (0 or 1)
    public var jValue: jvalue { .init(z: self.jboolean) }
}

extension Float: JValuable {
    /// Converts `Float` to JNI `jfloat`
    public var jValue: jvalue { .init(f: jfloat(self)) }
}

extension Double: JValuable {
    /// Converts `Double` to JNI `jdouble`
    public var jValue: jvalue { .init(d: jdouble(self)) }
}

extension UInt16: JValuable {
    /// Converts `UInt16` to JNI `jchar`
    public var jValue: jvalue { .init(c: jchar(self)) }
}

// MARK: - Objects

extension JObject: JValuable {
    /// Converts any Java object reference into JNI `jvalue`
    public var jValue: jvalue { .init(l: ref.ref) }
}

extension JClass: JValuable {
    /// Converts any Java object reference into JNI `jvalue`
    public var jValue: jvalue { .init(l: ref) }
}

extension JString: JValuable {
    public var jValue: jvalue { .init(l: ref.ref) }
}
#endif

public final class JDouble: Sendable, JObjectable {
    public let object: JObject

    public init? (_ value: Double) {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let clazz = JClass.load("java/lang/Double"),
            let global = clazz.newObject(env, args: value)
        else { return nil }
        self.object = JObject(global, clazz)
        #else
        return nil
        #endif
    }
}