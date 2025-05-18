//
//  JEnvable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 23.10.2021.
//

import Android

/// A protocol for types that provide access to a `JEnv` instance.
public protocol JEnvable {
    /// The JNI environment associated with the current thread or execution context.
    var env: JEnv { get }
}
