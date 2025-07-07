//
//  JObject.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if os(Android)
import Android
#endif

/// A Swift wrapper around a global `jobject`, retained safely across threads and JNI calls.
///
/// Use `JObject` to represent any Java object passed from or constructed in Swift.
/// It retains a global reference automatically to prevent premature GC.
public final class JObject: Sendable, JObjectable {
    /// The globally retained reference to the Java object.
    public let ref: JObjectBox
    
    /// The resolved `JClass` of this object.
    public let clazz: JClass

    /// Current `JObject` instance
    public var object: JObject { self }

    // MARK: - Init
    
    #if os(Android)
    /// Wrap an existing `jobject` by creating a global reference.
    /// - Parameters:
    ///   - ref: The local or global `jobject`
    ///   - className: The Java class name in JNI format (e.g. `"java/lang/String"`)
    ///   - clazz: The resolved `JClass` wrapper
    public init(_ ref: JObjectBox, _ clazz: JClass) {
        self.ref = ref
        self.clazz = clazz
    }

    /// Convenient overload for optional `ref` and `clazz`
    public init?(_ ref: JObjectBox?, _ clazz: JClass?) {
        guard let ref, let clazz else { return nil }
        self.ref = ref
        self.clazz = clazz
    }
    #endif
}
