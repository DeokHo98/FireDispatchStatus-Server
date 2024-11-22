//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/22/24.
//

import Vapor

// Response DTO
struct FCMTokenResponse: Content {
    let success: Bool
    let error: String?
}

// Request DTO
struct FCMTokenRequest: Content {
    let token: String
    let centerName: String
    let deviceId: String
}
