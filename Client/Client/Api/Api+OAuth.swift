//
//  Api+OAuth.swift
//  Client
//
//  Created by Даниил Виноградов on 18.12.2022.
//

import Foundation

extension Api {
    func getOAuthLink() async throws -> URL {
        let url = Api.base.appending(path: "oauth")
        let urlRequest = URLRequest(url: url)

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        guard let urlText = String(data: data, encoding: .utf8),
              let url = URL(string: urlText)
        else { throw ServerError.incorrectResponse }

        return url
    }
}
