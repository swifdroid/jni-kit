//
//  JMethodSignature.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

/// Represents a full JNI method signature, such as `(Ljava/lang/String;)I`.
/// Built from a list of parameter types and a return type using `JSignatureItem`.
public struct JMethodSignature: Sendable {
    /// The complete JNI signature string (e.g., `(I)V`)
    public let signature: String

    /// Initialize a method signature from parameter types and a return type.
    /// - Parameters:
    ///   - items: The parameter types as an array of `JSignatureItem`
    ///   - returning: The return type as a `JSignatureItem`
    public init(_ args: [JSignatureItem], returning: JSignatureItem) {
        self.signature = "(" + args.map(\.signature).joined() + ")" + returning.signature
    }

    /// Variadic version of init
    public init(_ args: JSignatureItem..., returning: JSignatureItem) {
        self.init(args, returning: returning)
    }
}
