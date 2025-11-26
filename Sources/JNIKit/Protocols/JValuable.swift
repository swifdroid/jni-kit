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

// MARK: - Java Objects for primitive types

public protocol JPrimitiveNumerable: JObjectable {}
extension JPrimitiveNumerable {
    /// Returns the value as a byte after a narrowing primitive conversion.
    public func byteValue() -> Int8? {
        callByteMethod(name: "byteValue")
    }

    /// Returns the value as a short after a narrowing primitive conversion.
    public func shortValue() -> Int16? {
        callShortMethod(name: "shortValue")
    }

    /// Returns the value as an int after a narrowing primitive conversion.
    public func intValue() -> Int32? {
        callIntMethod(name: "intValue")
    }

    /// Returns the value as a long after a widening primitive conversion.
    public func longValue() -> Int64? {
        callLongMethod(name: "longValue")
    }

    /// Returns the value as a double after a widening primitive conversion.
    public func doubleValue() -> Double? {
        callDoubleMethod(name: "doubleValue")
    }

    /// Returns the value as a float after a widening primitive conversion.
    public func floatValue() -> Float? {
        callFloatMethod(name: "floatValue")
    }
}

public typealias JByte = JInt8
public final class JInt8: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByIntegerLiteral {
    public static let className: JClassName = "java/lang/Byte"

    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (integerLiteral value: Int8) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: Int8) {
        self.init(integerLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}

public typealias JShort = JInt16
public final class JInt16: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByIntegerLiteral {
    public static let className: JClassName = "java/lang/Short"

    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (integerLiteral value: Int16) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: Int16) {
        self.init(integerLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}

public typealias JInt = JInt32
public typealias JInteger = JInt32
public final class JInt32: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByIntegerLiteral {
    public static let className: JClassName = "java/lang/Integer"

    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (integerLiteral value: Int32) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: Int32) {
        self.init(integerLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}

public typealias JLong = JInt64
public final class JInt64: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByIntegerLiteral {
    public static let className: JClassName = "java/lang/Long"

    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (integerLiteral value: Int64) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: Int64) {
        self.init(integerLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}

public final class JBool: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByBooleanLiteral {
    public static let className: JClassName = "java/lang/Boolean"

    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (booleanLiteral value: Bool) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: Bool) {
        self.init(booleanLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}

public final class JFloat: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByFloatLiteral {
    public static let className: JClassName = "java/lang/Float"

    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (floatLiteral value: Float) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: Float) {
        self.init(floatLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}

public final class JDouble: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByFloatLiteral {
    public static let className: JClassName = "java/lang/Double"
    
    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (floatLiteral value: Double) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: Double) {
        self.init(floatLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}

public typealias JChar = JUInt16
public typealias JCharacter = JUInt16
public final class JUInt16: Sendable, JPrimitiveNumerable, JSignatureItemable, ExpressibleByIntegerLiteral {
    public static let className: JClassName = "java/lang/Character"
    
    public let object: JObject

    public init (_ object: JObject) {
        self.object = object
    }

    public init (integerLiteral value: UInt16) {
        #if os(Android)
        let clazz = JClass.load(Self.className)!
        let global = clazz.newObject(args: value)!
        self.object = JObject(global, clazz)
        #else
        self.object = JObject(JObjectBox(), JClass(Self.className)) // Dummy
        #endif
    }

    public convenience init (_ value: UInt16) {
        self.init(integerLiteral: value)
    }

    public var signatureItemWithValue: JSignatureItemWithValue {
        .object(object, className)
    }
}