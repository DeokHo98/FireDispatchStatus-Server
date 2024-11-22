import Vapor

func routes(_ app: Application) throws {
    let controller = FireDispatchController()
    let fcmController = FCMController()
    try app.register(collection: fcmController)
    
    app.get("firedispatch", "list") { req async throws -> [FireDispatchResponse] in
        let data = try? await controller.index(req: req)
        return data ?? []
    }
    
    let fcmGroup = app.grouped("fcm")
    fcmGroup.post("register") { req async throws -> FCMTokenResponse in
        return await fcmController.create(req: req)
    }
    
    fcmGroup.post("delete") { req async throws -> FCMTokenResponse in
        return await fcmController.delete(req: req)
    }
    
    app.eventLoopGroup.next().scheduleRepeatedTask(
        initialDelay: .zero,
        delay: .seconds(60)
    ) { task in
        Task {
            try await controller.updateData(app: app)
        }
    }
}
