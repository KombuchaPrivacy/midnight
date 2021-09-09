import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    app.logger.info("Configuring application")
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // This is simpler now that we only have the two "Create..." Migrations to keep track of
    app.migrations.add(CreateSubscriptions())
    app.migrations.add(CreateRegistrationData())
    
    app.commands.use(CreateTokenCommand(), as: "create")
    app.commands.use(ListTokensCommand(), as: "list")
    app.commands.use(BadWordCommand(), as: "badword")
    
    app.logger.info("Setting up UIAA middleware")
    app.middleware.use(app.uiaaSessions.middleware)
    
    // Load our configuration file
    app.logger.info("Loading configuration file")
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    func getConfigData() throws -> Data {
        guard let localConfigData = try? Data(contentsOf: URL(fileURLWithPath: "midnight.json")) else {
            let globalConfigData = try Data(contentsOf: URL(fileURLWithPath: "/matrix/midnight/config/midnight.json"))
            return globalConfigData
        }
        return localConfigData
    }
    
    let configData = try getConfigData()
    let config = try decoder.decode(Config.self, from: configData)
    
    if let dbs = config.databaseServer {
        app.logger.info("Using Postgres database")
        app.databases.use(.postgres(
            hostname: dbs.host,
            port: dbs.port ?? PostgresConfiguration.ianaPortNumber,
            username: dbs.username,
            password: dbs.password,
            database: dbs.name
        ), as: .psql)
    } else {
        app.logger.info("Using SQLite database")
        if let dbFilename = config.databaseFile {
            app.logger.info("Using \(dbFilename) as sqlite db")
            app.databases.use(.sqlite(.file(dbFilename)), as: .sqlite)
        }
        else {
            app.logger.info("Using local midnight.sqlite")
            app.databases.use(.sqlite(.file("midnight.sqlite")), as: .sqlite)
        }
    }

    let ids = app.databases.ids()
    for id in ids {
        app.logger.info("Found database \(id)")
    }
    
    app.logger.info("Setting up the registration controller")
    let reg = RegistrationController(app: app,
                                     homeserver: config.homeserver,
                                     apiVersions: ["r0", "v1"],
                                     appStoreConfig: config.appStore)
    
    // register routes
    app.logger.info("Registering routes")
    try routes(app, reg: reg)
}
