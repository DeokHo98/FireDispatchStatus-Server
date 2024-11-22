//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/22/24.
//
import Fluent

struct CreateFCMToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("fcm_tokens")
            .id()
            .field("token", .string, .required)
            .field("center_name", .string, .required)
            .field("device_id", .string, .required)
            .unique(on: "token")
            .unique(on: "device_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("fcm_tokens").delete()
    }
}
