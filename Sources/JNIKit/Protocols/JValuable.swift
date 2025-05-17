//
//  JValuable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

import Android

/// A protocol that allows Swift types to be converted into a JNI-compatible `jvalue`
///
/// Conforming types can be passed directly into JNI method calls through convenience APIs.
/// For example: `callMethod(name: "add", args: [1, 2.0, true])`
public protocol JValuable {
    /// Convert the Swift value into a JNI `jvalue` union
    var jValue: jvalue { get }
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

extension UnicodeScalar: JValuable {
    /// Converts `UnicodeScalar` to JNI `jchar`
    public var jValue: jvalue { .init(c: jchar(self.value)) }
}

// MARK: - Objects

extension JObject: JValuable {
    /// Converts any Java object reference into JNI `jvalue`
    public var jValue: jvalue { .init(l: ref) }
}

extension JString: JValuable {
    public var jValue: jvalue { .init(l: ref) }
}