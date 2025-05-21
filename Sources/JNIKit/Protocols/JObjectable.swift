//
//  JObjectable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 23.10.2021.
//

import Android

/// A composite protocol that defines a common interface for interacting with any Java object (`jobject`) in Swift.
///
/// Once a type conforms to `JObjectable`, it automatically gains access to all
/// standard Java object methods through protocol extensions.
public protocol JObjectable: JEquatable, JGetClassable, JHashable, JNotifiable, JStringable, JWaitable {
    /// The underlying JNI object reference.
    var ref: jobject { get }

    /// The resolved class reference of the Java object.
    var clazz: JClass { get }

    /// The fully qualified class name of the object (e.g., `"java/lang/String"`).
    var className: JClassName { get }

    /// The wrapped Java object.
    var object: JObject { get }
}

extension JObjectable {
    /// Returns the class name of the object by accessing the `clazz.name` property.
    ///
    /// This provides a convenient default implementation based on the associated `clazz`.
    public var className: JClassName { clazz.name }
}
