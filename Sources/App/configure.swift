import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.http.server.configuration.hostname = "0.0.0.0"
    app.migrations.add(CreateFireDispatch())
    try await app.autoMigrate()
    try routes(app)
}
