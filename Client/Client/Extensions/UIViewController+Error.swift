//
//  UIViewController+Error.swift
//  Client
//
//  Created by Даниил Виноградов on 09.12.2022.
//

import UIKit

extension UIViewController {
    func perform<T>(_ function: () throws -> T) rethrows -> T? {
        do {
            return try function()
        } catch {
            showError(error)
            return nil
        }
    }

    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Oшибка", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: "Ок", style: .cancel))
        present(alert, animated: true)
    }
}
