//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/18/24.
//

import Fluent

struct CreateFireDispatch: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(FireDispatch.schema)
            .id()
            .field("center_name", .string, .required)
            .field("date", .string, .required)
            .field("state", .string, .required)
            .field("address", .string, .required)
            .field("dead_num", .int, .required)
            .field("injury_num", .int, .required)
            .field("side_over_num", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(FireDispatch.schema).delete()
    }
}
