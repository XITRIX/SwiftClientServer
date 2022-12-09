//
//  ToDoViewController.swift
//  Client
//
//  Created by Даниил Виноградов on 09.12.2022.
//

import UIKit

class ToDoViewController: UIViewController {
    @IBOutlet var tableView: UITableView!

    var models: [ToDoModel] = []
    lazy var dataSource = makeDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        updateAuthState()


        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = dataSource
        tableView.delegate = self

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        tableView.refreshControl = refresh

        navigationItem.rightBarButtonItem = .init(title: "Добавить", style: .done, target: self, action: #selector(add))
        navigationItem.leftBarButtonItem = .init(title: "Выйти", style: .plain, target: self, action: #selector(deauth))
        navigationItem.leftBarButtonItem?.tintColor = .systemRed
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAuthState), name: Api.authDidChange, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Int, ToDoModel> {
        .init(tableView: tableView) { tableView, _, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.textLabel?.text = itemIdentifier.title
            return cell
        }
    }

    @objc func refresh(_ sender: UIRefreshControl?) {
        Task {
            await reloadToDos()
            sender?.endRefreshing()
        }
    }

    @objc func add() {
        let alert = UIAlertController(title: "Добавить", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "ToDo"
        }
        alert.addAction(.init(title: "Отмена", style: .cancel))
        alert.addAction(.init(title: "Готово", style: .default) { [self] _ in
            Task {
                do {
                    try await Api.shared.addToDo(alert.textFields?.first?.text ?? "")
                    await reloadToDos()
                } catch {
                    showError(error)
                }
            }
        })
        present(alert, animated: true)
    }

    @objc func deauth() {
        Task {
            Api.shared.deauth()
            models.removeAll()
            await reloadTableView()
        }
    }

    @objc func updateAuthState() {
        if !Api.shared.isAuth {
            showLoginScreen()
        } else {
            Task { await reloadToDos() }
        }
    }
}

extension ToDoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        .init(actions: [.init(style: .destructive, title: "Удалить", handler: { [self] _, _, callback in
            Task {
                do {
                    let model = models[indexPath.row]
                    try await Api.shared.removeToDo(model)
                    await reloadToDos()
                    callback(true)
                } catch {
                    showError(error)
                    callback(false)
                }
            }
        })])
    }
}

private extension ToDoViewController {
    func reloadToDos() async {
        do {
            models = try await Api.shared.getToDos()
            await reloadTableView()
        } catch {
            showError(error)
        }
    }

    func reloadTableView() async {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ToDoModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(models, toSection: 0)
        await dataSource.apply(snapshot)
    }

    func showLoginScreen() {
        let vc = storyboard!.instantiateViewController(withIdentifier: "LoginViewController")
        present(vc, animated: true)
    }
}
