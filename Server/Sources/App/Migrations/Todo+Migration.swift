import Fluent

extension Todo {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("todos")
                .id()
                .field("title", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("todos").delete()
        }
    }

    struct Migration2: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("todos")
                .field("checkmark", .bool, .required, .sql(.default(false)))
                .update()
        }

        func revert(on database: Database) async throws {}
    }
}
