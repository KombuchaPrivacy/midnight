import Fluent
import FluentPostgresDriver
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
    
    // Load our configuration file
    let configData = try Data(contentsOf: URL(fileURLWithPath: "/matrix/chuckie/config/chuckie.json"))
    let decoder = JSONDecoder()
    let config = try decoder.decode(Config.self, from: configData)
    
    if let dbc = config.database {
        app.databases.use(.postgres(
            hostname: dbc.host,
            port: dbc.port ?? PostgresConfiguration.ianaPortNumber,
            username: dbc.username,
            password: dbc.password,
            database: dbc.name
        ), as: .psql)
    } else {
        app.databases.use(.sqlite(.file("/matrix/chuckie/data/db.sqlite")), as: .sqlite)
    }
    
    let reg = RegistrationController(app: app,
                                     homeserver: config.homeserver,
                                     /*
                                     homeserver: "beta.kombucha.social",
                                     homeserver_scheme: .https,
                                     homeserver_port: 443,
                                     */
                                     /*
                                     homeserver: "192.168.1.89",
                                     homeserver_scheme: .http,
                                     homeserver_port: 6167,
                                     */
                                     apiVersions: ["r0", "v1"])
    
    // register routes
    try routes(app, reg: reg)
}
