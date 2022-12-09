import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.post("register") { req async throws -> UserToken in
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        let user = try User(
            name: create.name,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        try await user.save(on: req.db)
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }

    let passwordProtected = app.grouped(User.authenticator())

    passwordProtected.post("login") { req async throws -> UserToken in
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }

    let tokenProtected = app.grouped(UserToken.authenticator())

    try tokenProtected
        .grouped(User.guardMiddleware())
        .register(collection: TodoController())

    tokenProtected.get("me") { req -> User in
        try req.auth.require(User.self)
    }

}
