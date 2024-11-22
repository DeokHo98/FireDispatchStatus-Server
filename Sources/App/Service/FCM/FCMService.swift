//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/22/24.
//

import Vapor
import Fluent

final class FCMService {
    func fetchTokens(for centerName: String, on db: Database) async throws -> [String] {
        try await FCM.query(on: db)
            .filter(\.$centerName == centerName)
            .all()
            .map { $0.token }
    }
}
