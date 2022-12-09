//
//  RegisterViewController.swift
//  Client
//
//  Created by Даниил Виноградов on 09.12.2022.
//

import UIKit

class RegisterViewController: UIViewController {
    @IBOutlet var login: UITextField!
    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var confirmPassword: UITextField!
    @IBOutlet var registerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        registerButton.layer.cornerRadius = 12
        registerButton.layer.cornerCurve = .continuous

        isModalInPresentation = true
    }

    @IBAction func register(_ sender: Any) {
        Task {
            do {
                try await Api.shared.register(name: login.text ?? "",
                                              email: email.text ?? "",
                                              password: password.text ?? "",
                                              confirmPassword: confirmPassword.text ?? "")
                dismiss(animated: true)
            } catch {
                showError(error)
            }
        }
    }
}
