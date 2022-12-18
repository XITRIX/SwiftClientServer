//
//  AuthController.swift
//  Client
//
//  Created by Даниил Виноградов on 18.12.2022.
//

import UIKit
import WebKit

class AuthController: UIViewController {
    private let initUrl: URL
    private let completion: (Result<URL, Error>) -> Void

    var webView: WKWebView {
        view as! WKWebView
    }

    private init(url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        initUrl = url
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = WKWebView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self

        let request = URLRequest(url: initUrl)
        webView.load(request)

        title = "Авторизация"
    }
}

extension AuthController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urr = navigationAction.request.url

        guard let url = navigationAction.request.url,
              url.pathComponents.contains("callback") == true
        else { return decisionHandler(.allow) }

        decisionHandler(.cancel)
        dismiss(animated: true) {
            self.completion(.success(url))
        }
    }
}

extension AuthController {
    static func present(from viewController: UIViewController, with url: URL) async -> Result<URL, Error> {
        await withCheckedContinuation { continuation in
            let auth = AuthController(url: url) { result in
                continuation.resume(with: .success(result))
            }
            let nvc = UINavigationController(rootViewController: auth)
            viewController.present(nvc, animated: true)
        }
    }
}
