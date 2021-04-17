import Fluent
//import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // This is simpler now that we only have the two "Create..." Migrations to keep track of
    app.migrations.add(CreateSubscriptions())
    app.migrations.add(CreateRegistrationData())
    
    app.commands.use(CreateTokenCommand(), as: "create")
    app.commands.use(ListTokensCommand(), as: "list")
    app.commands.use(BadWordCommand(), as: "badword")
    
    app.middleware.use(app.uiaaSessions.middleware)

    /*
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
    */
    
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    let reg = RegistrationController(app: app,
                                     homeserver: "beta.kombucha.social",
                                     homeserver_scheme: .https,
                                     homeserver_port: 443,
                                     //homeserver: "192.168.1.89",
                                     //homeserver_scheme: .http,
                                     //homeserver_port: 6167,
                                     apiVersions: ["r0", "v1"])
    
    // register routes
    try routes(app, reg: reg)
}
