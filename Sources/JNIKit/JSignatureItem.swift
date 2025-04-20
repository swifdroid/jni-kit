//
//  JSignatureItem.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

/// Represents a single type within a JNI method signature, such as `I`, `Ljava/lang/String;`, or `[D`.
public struct JSignatureItem: Sendable {
    /// The JNI type code prefix, such as `I`, `L`, `[L`, etc.
    private let typeCode: TypeCode

    /// The full class name path for object types, slash-separated.
    public let className: String

    /// Full signature fragment (e.g., `I`, `Ljava/lang/String;`, `[I`)
    public let signature: String

    /// Initialize a custom signature item.
    /// - Parameters:
    ///   - typeCode: Type prefix, e.g. `"L"` for object, `"[I"` for array of ints, `"I"` for int.
    ///   - names: For object types, the full `JClassName` path.
    ///   - semicolon: Whether to end the object type with `;`
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

    // MARK: - Object types

    /// Create a signature for an object (class) type.
    /// - Parameters:
    ///   - array: Whether this is an array of objects
    ///   - classes: One or more `JClassName` parts forming the full name
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