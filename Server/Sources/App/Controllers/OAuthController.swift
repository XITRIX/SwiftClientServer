//
//  File.swift
//  
//
//  Created by Даниил Виноградов on 18.12.2022.
//

import Fluent
import Vapor

struct AccessCode: Content {
    var code: String
}

struct Token: Content {
    var access_token: String
    var email: String
}

struct VKKeys {
    static let address = ""
    static let clientId = ""
    static let clientSecret = ""
}

struct OAuthController: RouteCollection {
    private let callbackUrl = VKKeys.address + "/oauth/callback"

    func boot(routes: RoutesBuilder) throws {
        let oauth = routes.grouped("oauth")
        oauth.get(use: auth)
//        oauth.get("token", use: authToken)
        oauth.get("callback", use: callback)
    }

    func auth(req: Request) async throws -> String {
        return "https://oauth.vk.com/authorize?client_id=\(VKKeys.clientId)&display=mobile&redirect_uri=\(callbackUrl)&scope=email&response_type=code&v=5.131"
    }

//    func authToken(req: Request) async throws -> String {
//        return try req.query.decode(Token.self)
//    }

    func callback(req: Request) async throws -> UserToken {
        let code = try req.query.decode(AccessCode.self)

        let res = try await req.client.get("https://oauth.vk.com/access_token?client_id=\(VKKeys.clientId)&client_secret=\(VKKeys.clientSecret)&redirect_uri=\(callbackUrl)&code=\(code.code)")
        let token = try res.content.decode(Token.self)

//        print(token.email)

        if let user = try await User.query(on: req.db).filter(\.$email == token.email).all().first {
            let token = try user.generateToken()
            try await token.save(on: req.db)
            return token
        }

        let user = User(
            name: "create.name",
            email: token.email,
            passwordHash: ""
        )

        try await user.save(on: req.db)
        let userToken = try user.generateToken()
        try await userToken.save(on: req.db)
        return userToken
    }
}
