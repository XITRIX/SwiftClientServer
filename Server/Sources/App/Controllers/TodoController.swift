import Fluent
import Vapor

struct TodoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")
        todos.get(use: index)
        todos.post(use: create)
        todos.group(":todoID") { todo in
            todo.delete(use: delete)
            todo.post(use: checkmark)
        }
    }

    func index(req: Request) async throws -> [Todo] {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        return try await Todo.query(on: req.db).filter(\.$user.$id == userId).all()
    }

    func create(req: Request) async throws -> Todo {
        let user = try req.auth.require(User.self)
        try Todo.Create.validate(content: req)
        let todoc = try req.content.decode(Todo.Create.self)
        let todo = Todo(title: todoc.title, checkmark: false, userID: try user.requireID())
        try await todo.save(on: req.db)
        return todo
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await todo.delete(on: req.db)
        return .noContent
    }

    func checkmark(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
            throw Abort(.notFound)
        }
        todo.checkmark.toggle()
        try await todo.save(on: req.db)
        return .ok
    }
}
