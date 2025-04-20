//
//  JNIKit.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

public actor JNIKit: Sendable {
    public static let shared = JNIKit()

    public private(set) var vm: JVM!

    private init() {}

    /// Initialize JNIKit with the JavaVM pointer
    public func initialize(with vm: JVM) {
        self.vm = vm
    }

    /// Attach current thread and get a JNIEnv*
    public func attachCurrentThread() -> JEnv? {
        vm.attachCurrentThread()
    }

    /// Detach current thread (optional)
    public func detachCurrentThread() {
        vm.detachCurrentThread()
    }
}