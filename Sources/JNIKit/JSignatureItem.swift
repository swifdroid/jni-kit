//
//  JSignatureItem.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if JNILOGS
#if canImport(Logging)
import Logging
#endif
#endif

/// Represents a single type fragment within a JNI method or field signature,
/// such as `"I"`, `"Ljava/lang/String;"`, or `"[D"`.
///
/// This structure enables type-safe construction of JNI signatures used with
/// `GetMethodID`, `GetFieldID`, or any method signature-based JNI call.
///
/// Example usage:
/// ```swift
/// let returnType: JSignatureItem = .object("java/lang/String")
/// let paramType: JSignatureItem = .int
/// let sig = MethodSignature([paramType], returning: returnType) // => "(I)Ljava/lang/String;"
/// ```
public struct JSignatureItem: Sendable {
    /// The raw JNI type code prefix, such as `"I"` for `int`, `"L"` for object, or `"[I"` for array of ints.
    public let typeCode: TypeCode

    /// The class name for object types, in slash-separated format (e.g., `"java/lang/String"`),
    /// or empty for primitive types.
    public let className: String

    /// The full signature string for this item, e.g. `"I"`, `"Ljava/lang/String;"`, or `"[F"`.
    public let signature: String

    // MARK: - Init

    /// Initializes a new `JSignatureItem` based on a `TypeCode` and an optional class name.
    ///
    /// - Parameters:
    ///   - typeCode: The JNI type prefix, such as `.object`, `.int`, or `.booleans`.
    ///   - name: A `JClassName` used for object types (e.g., `java/lang/String`). Ignored for primitives.
    public init(_ typeCode: TypeCode, _ name: JClassName? = nil) {
        if let name {
            let hasArrayPrefix = name.path.hasPrefix("[L")
            self.typeCode = hasArrayPrefix ? .objects : .object
            self.className = name.path + (name.path.hasSuffix(";") ? "" : ";")
            self.signature = hasArrayPrefix ? self.className : self.typeCode.rawValue + self.className
            #if JNILOGS
            Logger.debug("JSignatureItem name.path: \(name.path) hasPrefix: \(name.path.hasPrefix("[L")) signature: \(self.signature)")
            #endif
        } else {
            self.typeCode = typeCode
            self.className = ""
            self.signature = typeCode.rawValue
        }
    }

    // MARK: - Primitive Types

    /// Represents JNI type `V` (void)
    public static var void: Self { .init(.void) }

    /// JNI primitives
    public static var boolean: Self { .init(.boolean) }
    public static var byte: Self    { .init(.byte) }
    public static var char: Self    { .init(.char) }
    public static var short: Self   { .init(.short) }
    public static var int: Self     { .init(.int) }
    public static var long: Self    { .init(.long) }
    public static var float: Self   { .init(.float) }
    public static var double: Self  { .init(.double) }

    // MARK: - Primitive Arrays

    /// Arrays of primitives
    public static var booleans: Self { .init(.booleans) }
    public static var bytes: Self    { .init(.bytes) }
    public static var chars: Self    { .init(.chars) }
    public static var shorts: Self   { .init(.shorts) }
    public static var ints: Self     { .init(.ints) }
    public static var longs: Self    { .init(.longs) }
    public static var floats: Self   { .init(.floats) }
    public static var doubles: Self  { .init(.doubles) }

    /// 2D Arrays of primitives
    public static var booleans2D: Self { .init(.booleans2D) }
    public static var bytes2D: Self    { .init(.bytes2D) }
    public static var chars2D: Self    { .init(.chars2D) }
    public static var shorts2D: Self   { .init(.shorts2D) }
    public static var ints2D: Self     { .init(.ints2D) }
    public static var longs2D: Self    { .init(.longs2D) }
    public static var floats2D: Self   { .init(.floats2D) }
    public static var doubles2D: Self  { .init(.doubles2D) }

    // MARK: - Object Types

    /// Construct a signature item representing a reference type (`L...;`) or object array (`[L...;`).
    ///
    /// - Parameters:
    ///   - array: Whether this is an array of the object type
    ///   - clazz: The class name wrapped as `JClassName` (e.g., `java/lang/String`)
    /// - Returns: A valid signature item like `"Ljava/lang/String;"` or `"[Ljava/lang/String;"`
    public static func object(array: Bool = false, _ clazz: JClassName) -> Self {
        .init(array ? .objects : .object, clazz)
    }
}

extension JSignatureItem: JTypeSignature {
    /// Indicates whether the signature item represents an object or object array type.
    ///
    /// This returns `true` if the `typeCode` corresponds to either:
    /// - `.object` → a single object reference (e.g., `Ljava/lang/String;`)
    /// - `.objects` → an array of objects (e.g., `[Ljava/lang/String;`)
    ///
    /// This is useful for logic that must distinguish between primitive types and reference types,
    /// such as deciding whether a trailing `;` is required or whether class names apply.
    ///
    /// Example:
    /// ```swift
    /// if item.isObject {
    ///     print("This is a reference type")
    /// }
    /// ```
    public var isObject: Bool {
        [.object, .objects].contains(typeCode)
    }
}
public enum JSignatureItemWithValue: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { self }

    /// JNI primitives
    case boolean(Bool)
    case byte(Int8)
    case char(UInt16)
    case short(Int16)
    case int(Int32)
    case long(Int64)
    case float(Float)
    case double(Double)

    /// JNI primitive arrays
    case booleanArray([Bool])
    case byteArray([Int8])
    case charArray([UInt16])
    case shortArray([Int16])
    case intArray([Int32])
    case longArray([Int64])
    case floatArray([Float])
    case doubleArray([Double])

    /// JNI primitive two-level-arrays
    case booleanArray2D([[Bool]])
    case byteArray2D([[Int8]])
    case charArray2D([[UInt16]])
    case shortArray2D([[Int16]])
    case intArray2D([[Int32]])
    case longArray2D([[Int64]])
    case floatArray2D([[Float]])
    case doubleArray2D([[Double]])

    // MARK: Object

    case object(JObject, JClassName)
    case objectNil(JClassName)

    // MARK: Signature Item
    
    #if os(Android)
    public var value: any JValuable {
        switch self {
            case .boolean(let value): return value
            case .byte(let value): return value
            case .char(let value): return value
            case .short(let value): return value
            case .int(let value): return value
            case .long(let value): return value
            case .float(let value): return value
            case .double(let value): return value
            case .booleanArray(let value): return JBoolArray(value)!
            case .byteArray(let value): return JInt8Array(value)!
            case .charArray(let value): return JUInt16Array(value)!
            case .shortArray(let value): return JInt16Array(value)!
            case .intArray(let value): return JIntArray(value)!
            case .longArray(let value): return JInt64Array(value)!
            case .floatArray(let value): return JFloatArray(value)!
            case .doubleArray(let value): return JDoubleArray(value)!
            case .booleanArray2D(let value): return JBoolArray2D(value)!
            case .byteArray2D(let value): return JInt8Array2D(value)!
            case .charArray2D(let value): return JUInt16Array2D(value)!
            case .shortArray2D(let value): return JInt16Array2D(value)!
            case .intArray2D(let value): return JIntArray2D(value)!
            case .longArray2D(let value): return JInt64Array2D(value)!
            case .floatArray2D(let value): return JFloatArray2D(value)!
            case .doubleArray2D(let value): return JDoubleArray2D(value)!
            case .object(let value, _): return value
            case .objectNil(_): return JNull()
        }
    }
    #endif
    
    public var signatureItem: JSignatureItem {
        switch self {
            case .boolean: return .boolean
            case .byte: return .byte
            case .char: return .char
            case .short: return .short
            case .int: return .int
            case .long: return .long
            case .float: return .float
            case .double: return .double
            case .booleanArray: return .booleans
            case .byteArray: return .bytes
            case .charArray: return .chars
            case .shortArray: return .shorts
            case .intArray: return .ints
            case .longArray: return .longs
            case .floatArray: return .floats
            case .doubleArray: return .doubles
            case .booleanArray2D: return .booleans2D
            case .byteArray2D: return .bytes2D
            case .charArray2D: return .chars2D
            case .shortArray2D: return .shorts2D
            case .intArray2D: return .ints2D
            case .longArray2D: return .longs2D
            case .floatArray2D: return .floats2D
            case .doubleArray2D: return .doubles2D
            case .object(_, let className): return .object(className)
            case .objectNil(let className): return .object(className)
        }
    }
}
public protocol JSignatureItemable {
    var signatureItemWithValue: JSignatureItemWithValue { get }
}
extension JObject: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .object(self, className) }
}
extension JString: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { self.signedAsString() }
}
extension String: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { self.wrap().signedAsString() }
}
extension Optional: JSignatureItemable where Wrapped: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue {
        switch self {
        case .some(let value):
            return value.signatureItemWithValue
        case .none:
            switch Wrapped.self {
            case is JInt8.Type: return .objectNil(JInt8.className)
            case is JInt16.Type: return .objectNil(JInt16.className)
            case is JInt32.Type: return .objectNil(JInt32.className)
            case is JInt64.Type: return .objectNil(JInt64.className)
            case is JUInt16.Type: return .objectNil(JUInt16.className)
            case is JBool.Type: return .objectNil(JBool.className)
            case is JFloat.Type: return .objectNil(JFloat.className)
            case is JDouble.Type: return .objectNil(JDouble.className)
            case is JObject.Type: fatalError("Unsigned Optional<JObject> is not supported, use Optional<JObject>.signed(as: JClassName) instead")
            default: fatalError("Optional<\(Wrapped.self)> is not supported")
            }
        }
    }
}
extension Int8: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .byte(self) }
}
extension Int16: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .short(self) }
}
extension Int32: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .int(self) }
}
extension Int64: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .long(self) }
}
extension Bool: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .boolean(self) }
}
extension Float: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .float(self) }
}
extension Double: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .double(self) }
}
extension UInt16: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .char(self) }
}
extension JObject {
    public func signed(as className: JClassName? = nil) -> JSignatureItemWithValue {
        .object(self, className ?? self.className)
    }
}
extension Optional where Wrapped == JObject {
    public func signed(as className: JClassName) -> JSignatureItemWithValue { 
        if let value = self {
            return .object(value, className)
        } else {
            return .objectNil(className)
        }
    }
}
extension JObjectable {
    public func signed(as className: JClassName? = nil) -> JSignatureItemWithValue {
        .object(self.object, className ?? self.className)
    }
}
extension Optional where Wrapped: JObjectable {
    public func signed(as className: JClassName) -> JSignatureItemWithValue { 
        if let value = self {
            return .object(value.object, className)
        } else {
            return .objectNil(className)
        }
    }
}
extension JString {
    public func signedAsString() -> JSignatureItemWithValue {
        signed(as: "java/lang/String")
    }

    public func signedAsCharSequence() -> JSignatureItemWithValue {
        signed(as: "java/lang/CharSequence")
    }
}
extension Optional where Wrapped == JString {
    public func signedAsString() -> JSignatureItemWithValue {
        signed(as: "java/lang/String")
    }

    public func signedAsCharSequence() -> JSignatureItemWithValue {
        signed(as: "java/lang/CharSequence")
    }
}
extension String {
    public func signedAsString() -> JSignatureItemWithValue {
        wrap().signed(as: "java/lang/String")
    }

    public func signedAsCharSequence() -> JSignatureItemWithValue {
        wrap().signed(as: "java/lang/CharSequence")
    }
}
extension Optional where Wrapped == String {
    public func signedAsString() -> JSignatureItemWithValue {
        if let value = self {
            return value.wrap().signedAsString()
        } else {
            return .objectNil("java/lang/String")
        }
    }

    public func signedAsCharSequence() -> JSignatureItemWithValue {
        if let value = self {
            return value.wrap().signedAsCharSequence()
        } else {
            return .objectNil("java/lang/CharSequence")
        }
    }
}

public protocol PrimitiveJavaType {
    static var typeCode: TypeCode { get }
}
extension Int8: PrimitiveJavaType {
    public static let typeCode: TypeCode = .byte
}
extension Int16: PrimitiveJavaType {
    public static let typeCode: TypeCode = .short
}
extension Int32: PrimitiveJavaType {
    public static let typeCode: TypeCode = .int
}
extension Int64: PrimitiveJavaType {
    public static let typeCode: TypeCode = .long
}
extension UInt16: PrimitiveJavaType {
    public static let typeCode: TypeCode = .char
}
extension Bool: PrimitiveJavaType {
    public static let typeCode: TypeCode = .boolean
}
extension Float: PrimitiveJavaType {
    public static let typeCode: TypeCode = .float
}
extension Double: PrimitiveJavaType {
    public static let typeCode: TypeCode = .double
}
extension [Int8] {
    public static let typeCode: TypeCode = .bytes
}
extension [Int16] {
    public static let typeCode: TypeCode = .shorts
}
extension Array: PrimitiveJavaType where Element: PrimitiveJavaType {
    public static var typeCode: TypeCode {
        switch Element.typeCode {
            case .byte: return .bytes
            case .short: return .shorts
            case .int: return .ints
            case .long: return .longs
            case .char: return .chars
            case .boolean: return .booleans
            case .float: return .floats
            case .double: return .doubles
            case .bytes: return .bytes2D
            case .shorts: return .shorts2D
            case .ints: return .ints2D
            case .longs: return .longs2D
            case .chars: return .chars2D
            case .booleans: return .booleans2D
            case .floats: return .floats2D
            case .doubles: return .doubles2D
            default: fatalError("Array<Array<\(Element.self)>> is not supported")
        }
    }
}
/// A protocol for efficient, copy-free interoperability with Java arrays in Swift-for-Android environments.
///
/// Provides unified iteration over both Swift `Array` and `InlineArray` types while avoiding
/// unnecessary memory copies. The protocol offers two access patterns:
///
/// - **Zero-copy iteration**: Use `makeIterator()` for sequential access without creating copies
/// - **Optional direct access**: Use `array` property when you specifically need a Swift `Array`
///
/// ## Performance Characteristics:
/// - `Array`: Zero-copy iteration, direct array access returns self
/// - `InlineArray`: Zero-copy iteration, array access returns `nil` to avoid copying
///
/// ## Usage Example:
/// ```swift
/// func processJavaArray<T: ToJavaArrayIterable>(_ array: T) where T.Element == Int32 {
///     // Efficient iteration without copying
///     for element in array.makeIterator() {
///         processElement(element)
///     }
///
///     // Get Swift Array only if available without copy
///     if let swiftArray = array.array {
///         // Use direct array access (only works for Array, not InlineArray)
///         performArrayOperations(swiftArray)
///     } else {
///         // Fallback for InlineArray - iterate without copying
///         for i in 0..<array.count {
///             processElement(array.makeIterator().next()!)
///         }
///     }
/// }
/// ```
///
/// - Note: The `array` property returns `nil` for `InlineArray` to prevent expensive copying
///   operations. Use iterator-based access for optimal performance with both array types.
public protocol ToJavaArrayIterable {
    associatedtype Element
    var array: [Element]? { get }
    func makeIterator() -> AnyIterator<Element>
    var count: Int { get }
}
#if compiler(>=6.2)
extension InlineArray: ToJavaArrayIterable {
    public var array: [Element]? { nil }
    public func makeIterator() -> AnyIterator<Element> {
        var index = 0
        return AnyIterator {
            guard index < self.count else { return nil }
            defer { index += 1 }
            return self[index]
        }
    }
}
#endif
extension Array: ToJavaArrayIterable {
    public var array: [Element]? { self }
    public func makeIterator() -> AnyIterator<Element> {
        var index = 0
        return AnyIterator {
            guard index < self.count else { return nil }
            defer { index += 1 }
            return self[index]
        }
    }
}
#if compiler(>=6.2)
extension InlineArray: JSignatureItemable where Element: PrimitiveJavaType {
    public var signatureItemWithValue: JSignatureItemWithValue {
        switch Element.typeCode {
            case .byte: return .byteArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! Int8 })
            case .short: return .shortArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! Int16 })
            case .int: return .intArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! Int32 })
            case .long: return .longArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! Int64 })
            case .char: return .charArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! UInt16 })
            case .boolean: return .booleanArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! Bool })
            case .float: return .floatArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! Float })
            case .double: return .doubleArray(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! Double })
            case .bytes: return .byteArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [Int8] })
            case .shorts: return .shortArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [Int16] })
            case .ints: return .intArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [Int32] })
            case .longs: return .longArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [Int64] })
            case .chars: return .charArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [UInt16] })
            case .booleans: return .booleanArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [Bool] })
            case .floats: return .floatArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [Float] })
            case .doubles: return .doubleArray2D(self.count == 0 ? [] : (0..<self.count).map { self[$0] as! [Double] })
            default: fatalError("InlineArray<\(Element.self)> is not supported")
        }
    }
}
#endif
extension Array: JSignatureItemable where Element: PrimitiveJavaType {
    public var signatureItemWithValue: JSignatureItemWithValue {
        switch Element.typeCode {
            case .byte: return .byteArray(self.map { $0 as! Int8 })
            case .short: return .shortArray(self.map { $0 as! Int16 })
            case .int: return .intArray(self.map { $0 as! Int32 })
            case .long: return .longArray(self.map { $0 as! Int64 })
            case .char: return .charArray(self.map { $0 as! UInt16 })
            case .boolean: return .booleanArray(self.map { $0 as! Bool })
            case .float: return .floatArray(self.map { $0 as! Float })
            case .double: return .doubleArray(self.map { $0 as! Double })
            case .bytes: return .byteArray2D(self.map { $0 as! [Int8] })
            case .shorts: return .shortArray2D(self.map { $0 as! [Int16] })
            case .ints: return .intArray2D(self.map { $0 as! [Int32] })
            case .longs: return .longArray2D(self.map { $0 as! [Int64] })
            case .chars: return .charArray2D(self.map { $0 as! [UInt16] })
            case .booleans: return .booleanArray2D(self.map { $0 as! [Bool] })
            case .floats: return .floatArray2D(self.map { $0 as! [Float] })
            case .doubles: return .doubleArray2D(self.map { $0 as! [Double] })
            default: fatalError("Array<\(Element.self)> is not supported")
        }
    }
}

extension Array where Element == [Int8] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .byteArray2D(self)
    }
}
extension Array where Element == [Int16] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .shortArray2D(self)
    }
}
extension Array where Element == [Int32] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .intArray2D(self)
    }
}
extension Array where Element == [Int64] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .longArray2D(self)
    }
}
extension Array where Element == [UInt16] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .charArray2D(self)
    }
}
extension Array where Element == [Bool] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .booleanArray2D(self)
    }
}
extension Array where Element == [Float] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .floatArray2D(self)
    }
}
extension Array where Element == [Double] {
    public var signatureItemWithValue: JSignatureItemWithValue {
        .doubleArray2D(self)
    }
}