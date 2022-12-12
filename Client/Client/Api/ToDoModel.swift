//
//  ToDoModel.swift
//  Client
//
//  Created by Даниил Виноградов on 09.12.2022.
//

import Foundation

struct ToDoModel: Codable, Identifiable {
    var id: UUID
    var title: String
    var checkmark: Bool

    var identity: AnyHashable { id }
}
