//
//  ViewController.swift
//  Client
//
//  Created by Даниил Виноградов on 07.12.2022.
//

import UIKit
import WebKit

class LoginViewController: UIViewController {
    @IBOutlet var login: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var authButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        authButton.layer.cornerRadius = 12
        authButton.layer.cornerCurve = .continuous

        isModalInPresentation = true
    }

    @IBAction func login(_ sender: Any) {
        Task {
            do {
                try await Api.shared.login(username: login.text ?? "", password: password.text ?? "")
                dismiss(animated: true)
            } catch {
                showError(error)
            }
        }
    }

    @IBAction func vkAuthAction(_ sender: Any) {
        Task {
            do {
                let link = try await Api.shared.getOAuthLink()
                let codeUrl = try await AuthController.present(from: self, with: link).get()
                try await Api.shared.auth(with: codeUrl)
                dismiss(animated: true)
            } catch {
                showError(error)
            }
        }
    }
}
