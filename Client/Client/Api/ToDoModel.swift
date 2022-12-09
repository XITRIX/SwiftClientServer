//
//  ToDoModel.swift
//  Client
//
//  Created by Даниил Виноградов on 09.12.2022.
//

import Foundation

struct ToDoModel: Codable, Hashable {
    var id: UUID
    var title: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
