import Fluent
import FluentSQLiteDriver
import Vapor
import FCM

public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    app.migrations.add(CreateFireDispatch())
    app.migrations.add(CreateFCMToken())
    app.fcm.configuration = .envServiceAccountKey
    try await app.autoMigrate()
    try routes(app)
}
