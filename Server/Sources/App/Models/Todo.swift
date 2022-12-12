import Fluent
import Vapor

final class Todo: Model, Content {
    static let schema = "todos"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "checkmark")
    var checkmark: Bool

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, title: String, checkmark: Bool, userID: User.IDValue) {
        self.id = id
        self.title = title
        self.checkmark = checkmark
        self.$user.id = userID
    }
}

extension Todo {
    struct Create: Content {
        var title: String
    }
}

extension Todo.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty, customFailureDescription: "Название не может быть пустым")
    }
}

