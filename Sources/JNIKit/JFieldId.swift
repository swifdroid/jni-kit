//
//  JFieldId.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

public struct JFieldId: @unchecked Sendable {
    public let id: jfieldID
    
    public init(_ id: jfieldID) {
        self.id = id
    }

    /// Convenient overload for optional `id`
    public init?(_ id: jfieldID?) {
        guard let id else { return nil }
        self.id = id
    }
}