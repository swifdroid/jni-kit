//
//  JObject.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

#if JNILOGS
#if canImport(Logging)
import Logging
#endif
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

    private let isProxy: Bool

    private let debuggingNote: String

    // MARK: - Init

    /// Consume existing `JObject` and glue it with the right `JClass`
    public init(_ object: consuming JObject, _ clazz: JClass, debuggingNote: String? = nil, file: String = #file, function: String = #function,  line: Int = #line) {
        self.ref = object.ref
        self.clazz = clazz
        self.isProxy = false
        self.debuggingNote = debuggingNote ?? "file: \(file) function: \(function) line: \(line)"
        #if JNILOGS
        Logger.info("🗃️🗃️🗃️ JObject init 1 non-proxy ref: \(ref.ref) for \(clazz.name.fullName) note: \(debuggingNote)")
        #endif
    }
    
    /// Wrap an existing `jobject` global reference in the box with a `JClass`.
    /// - Parameters:
    ///   - ref: The global `jobject` in the box
    ///   - clazz: The Java class object representing the type of this `jobject`
    ///   - proxy: Mark it `true` to avoid deleting the reference on deinit
    public init(_ ref: JObjectBox, _ clazz: JClass, proxy: Bool = false, debuggingNote: String? = nil, file: String = #file, function: String = #function,  line: Int = #line) {
        self.ref = ref
        self.clazz = clazz
        self.isProxy = proxy
        self.debuggingNote = debuggingNote ?? "file: \(file) function: \(function) line: \(line)"
        #if JNILOGS
        Logger.info("🗃️🗃️🗃️ JObject init 2 non-proxy ref: \(ref.ref) for \(clazz.name.fullName) note: \(debuggingNote)")
        #endif
    }

    /// Convenient overload for optional `ref` and `clazz`
    public init?(_ ref: consuming JObjectBox?, _ clazz: JClass?, debuggingNote: String? = nil, file: String = #file, function: String = #function,  line: Int = #line) {
        guard let ref, let clazz else { return nil }
        self.ref = ref
        self.clazz = clazz
        self.isProxy = false
        self.debuggingNote = debuggingNote ?? "file: \(file) function: \(function) line: \(line)"
        #if JNILOGS
        Logger.info("🗃️🗃️🗃️ JObject init 3 non-proxy ref: \(ref.ref) for \(clazz.name.fullName) note: \(debuggingNote)")
        #endif
    }

    /// Private initializer to create a proxy object with a different class. Useful for casting.
    private init(original object: JObject, _ clazz: JClass, isProxy: Bool, debuggingNote: String? = nil, file: String = #file, function: String = #function,  line: Int = #line) {
        self.ref = object.ref
        self.clazz = clazz
        self.isProxy = isProxy
        self.debuggingNote = debuggingNote ?? "file: \(file) function: \(function) line: \(line)"
        #if JNILOGS
        Logger.info("🗃️🗃️🗃️ JObject init 4 proxy ref: \(ref.ref) for \(clazz.name.fullName) note: \(debuggingNote)")
        #endif
    }

    deinit {
        if !isProxy {
            #if JNILOGS
            Logger.critical("🧹🧹🧹 JObject deleted ref: \(ref.ref) for \(clazz.name.fullName) note: \(debuggingNote)")
            #endif
            #if os(Android)
            JEnv.current()?.deleteGlobalRef(self)
            #endif
        }
    }

    /// Returns same object reference but with the different class.
    public func cast(to className: JClassName) -> JObject? {
        guard let clazz = JClass.load(className) else { return nil }
        return JObject(original: self, clazz, isProxy: true, debuggingNote: debuggingNote)
    }
}
