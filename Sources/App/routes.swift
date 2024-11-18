import Vapor

func routes(_ app: Application) throws {
    let controller = FireDispatchController()
    
    app.get("firedispatch", "list") { req async throws -> [FireDispatchResponse] in
        let data = try? await controller.index(req: req)
        return data ?? []
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
