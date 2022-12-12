//
//  Api.swift
//  Client
//
//  Created by Даниил Виноградов on 09.12.2022.
//

import Foundation

struct UserToken: Codable {
    var value: String
}

struct ServerError: Codable, LocalizedError {
    var error: Bool
    var reason: String

    var errorDescription: String? {
        reason
    }

    static var notAuth: ServerError {
        .init(error: true, reason: "Not auth")
    }
}

class Api {
    static var authDidChange: NSNotification.Name { .init(rawValue: "ApiAuthDidChange") }
    private static let base = URL(string: "http://192.168.1.144:8080")!

    static let shared = Api()

    private var authToken: String? {
        didSet {
            UserDefaults.standard.set(authToken, forKey: "authToken")
            NotificationCenter.default.post(name: Api.authDidChange, object: self)
        }
    }

    var isAuth: Bool {
        authToken != nil
    }

    init() {
        authToken = UserDefaults.standard.value(forKey: "authToken") as? String
    }

    func deauth() {
        authToken = nil
    }

    func login(username: String, password: String) async throws {
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()

        let url = Api.base.appending(path: "login")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let user = try data.decode() as UserToken
        authToken = user.value
        print(user.value)
    }

    func register(name: String, email: String, password: String, confirmPassword: String) async throws {
        let json: [String: Any] =
            ["name": name,
             "email": email,
             "password": password,
             "confirmPassword": confirmPassword]

        let jsonData = try JSONSerialization.data(withJSONObject: json)

        let url = Api.base.appending(path: "register")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData

        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let user = try data.decode() as UserToken
        authToken = user.value
        print(user.value)
    }

    func getToDos() async throws -> [ToDoModel] {
        guard let authToken = authToken
        else { throw ServerError.notAuth }

        let url = Api.base.appending(path: "todos")
        var urlRequest = URLRequest(url: url)

        urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try data.decode() as [ToDoModel]
    }

    func addToDo(_ title: String) async throws {
        guard let authToken = authToken
        else { throw ServerError.notAuth }

        let json: [String: Any] =
            ["title": title]

        let jsonData = try JSONSerialization.data(withJSONObject: json)

        let url = Api.base.appending(path: "todos")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData

        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        try data.decode()
    }

    func removeToDo(_ model: ToDoModel) async throws {
        guard let authToken = authToken
        else { throw ServerError.notAuth }

        let url = Api.base.appending(path: "todos").appending(path: model.id.uuidString)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"

        urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        try data.decode()
    }

    func toggleCheckmark(_ model: ToDoModel) async throws {
        guard let authToken = authToken
        else { throw ServerError.notAuth }

        let url = Api.base.appending(path: "todos").appending(path: model.id.uuidString)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        try data.decode()
    }
}

extension Data {
    func decode() throws {
        if let error = try? JSONDecoder().decode(ServerError.self, from: self) {
            throw error
        }
    }

    func decode<T: Decodable>() throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: self)
        } catch {
            let error = try JSONDecoder().decode(ServerError.self, from: self)
            throw error
        }
    }
}
