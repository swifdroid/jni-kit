//
//  JEnvable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 23.10.2021.
//

import Android

public protocol JEnvable {
    var env: JEnv { get }
}
