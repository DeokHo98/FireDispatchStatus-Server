//
//  File.swift
//  
//
//  Created by Jeong Deokho on 11/22/24.
//
import Vapor
import Fluent

struct FCMController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let fcmRoutes = routes.grouped("fcm")
        fcmRoutes.post("register", use: create)
        fcmRoutes.delete("delete", ":token", use: delete)
    }
    
    @Sendable
    func create(req: Request) async -> FCMTokenResponse {
        do {
            let tokenData = try req.content.decode(FCMTokenRequest.self)
            if let existingToken = try? await FCM.query(on: req.db)
                .filter(\.$token == tokenData.token)
                .first() {
                // 기존 토큰 업데이트
                existingToken.centerName = tokenData.centerName
                existingToken.deviceId = tokenData.deviceId
                try await existingToken.save(on: req.db)
                return FCMTokenResponse(success: true, error: nil)
            }
            let token = FCM(
                token: tokenData.token,
                centerName: tokenData.centerName,
                deviceId: tokenData.deviceId
            )
            try await token.save(on: req.db)
            print("[ INFO ] 토큰 저장 성공 \(token)")
            return FCMTokenResponse(success: true, error: nil)
        } catch {
            print("[ INFO ] 토큰 저장 실패 \(error)")
            return FCMTokenResponse(success: false, error: error.localizedDescription)
        }
    }
    
    @Sendable
    func delete(req: Request) async -> FCMTokenResponse {
        do {
            let parameters = try req.content.decode([String: String].self)
            guard let deviceId = parameters["deviceId"] else {
                return .init(success: false, error: "deviceId가 필요합니다.")
            }
            guard let fcmToken = try await FCM.query(on: req.db)
                .filter(\.$deviceId == deviceId)
                .first() else {
                return .init(success: false, error: "해당하는 Token이 존재하지 않습니다.")
            }
            try await fcmToken.delete(on: req.db)
            print("[ INFO ] 토큰 삭제 성공 \(deviceId)")
            return .init(success: true, error: nil)
        } catch {
            print("[ INFO ] 토큰 삭제 실패 \(error)")
            return .init(success: false, error: error.localizedDescription)
        }
    }
}
