//
//  JSignatureItem.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

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
        let needsSemicolon = typeCode == .object || typeCode == .objects
        self.typeCode = typeCode
        self.className = (name?.path ?? "") + (needsSemicolon ? ";" : "")
        self.signature = typeCode.rawValue + self.className
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
    case char(UnicodeScalar)
    case short(Int16)
    case int(Int32)
    case long(Int64)
    case float(Float)
    case double(Double)

    // MARK: Object

    case object(JObject, JClassName)

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
            case .object(let value, _): return value
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
            case .object(_, let className): return .object(className)
        }
    }
}
public protocol JSignatureItemable {
    var signatureItemWithValue: JSignatureItemWithValue { get }
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
extension UnicodeScalar: JSignatureItemable {
    public var signatureItemWithValue: JSignatureItemWithValue { .char(self) }
}
extension JObject {
    public func signed(as className: JClassName? = nil) -> JSignatureItemWithValue {
        .object(self, className ?? self.className)
    }
}
extension JObjectable {
    public func signed(as className: JClassName? = nil) -> JSignatureItemWithValue {
        .object(self.object, className ?? self.className)
    }
}