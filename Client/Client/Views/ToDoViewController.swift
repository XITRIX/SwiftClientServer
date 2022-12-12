//
//  ToDoViewController.swift
//  Client
//
//  Created by Даниил Виноградов on 09.12.2022.
//

import UIKit

struct SectionModel {
    var title: String
    var models: [ToDoModel]
}

class ToDoViewController: UIViewController {
    @IBOutlet var tableView: UITableView!

    var models: [SectionModel] = []
    lazy var dataSource = makeDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        updateAuthState()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Header")
        tableView.delegate = self

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        tableView.refreshControl = refresh

        navigationItem.rightBarButtonItem = .init(title: "Добавить", style: .done, target: self, action: #selector(add))
        navigationItem.leftBarButtonItem = .init(title: "Выйти", style: .plain, target: self, action: #selector(deauth))
        navigationItem.leftBarButtonItem?.tintColor = .systemRed

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAuthState), name: Api.authDidChange, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func makeDataSource() -> UITableViewComparableDataSource<String, ToDoModel> {
        .init(tableView: tableView) { tableView, _, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.textLabel?.text = itemIdentifier.title
            cell.accessoryType = itemIdentifier.checkmark ? .checkmark : .none
            return cell
        } cellUpdater: { _, cell, _, itemIdentifier in
            cell.textLabel?.text = itemIdentifier.title
            cell.accessoryType = itemIdentifier.checkmark ? .checkmark : .none
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
        Api.shared.deauth()
        models.removeAll()
        reloadTableView()
    }

    @objc func updateAuthState() {
        if !Api.shared.isAuth {
            showLoginScreen()
        } else {
            Task { await reloadToDos() }
        }
    }

    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point)
        else { return }

        var model = models[indexPath.section].models[indexPath.row]

        if sender.state == .began {
            let alert = UIAlertController(title: "Переименовать", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "ToDo"
                textField.text = model.title
            }
            alert.addAction(.init(title: "Готово", style: .default) { [self] _ in
                Task {
                    do {
                        model.title = alert.textFields?.first?.text ?? ""
                        try await Api.shared.rename(model)
                        await reloadToDos()
                    } catch {
                        showError(error)
                    }
                }
            })
            alert.addAction(.init(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }
}

extension ToDoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        .init(actions: [.init(style: .destructive, title: "Удалить", handler: { [self] _, _, callback in
            Task {
                do {
                    let model = models[indexPath.section].models[indexPath.row]
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        Task {
            do {
                let model = models[indexPath.section].models[indexPath.row]
                try await Api.shared.toggleCheckmark(model)
                await reloadToDos()
            } catch {
                showError(error)
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !models.isEmpty else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header")!
        var content = header.defaultContentConfiguration()
        content.text = models[section].title
        header.contentConfiguration = content
        return header
    }
}

private extension ToDoViewController {
    func reloadToDos() async {
        do {
            let localModels = try await Api.shared.getToDos()
                .sorted(by: { $0.title.caseInsensitiveCompare($1.title) == .orderedAscending })
                .sorted(by: { $0.checkmark && !$1.checkmark })

            models = Dictionary(grouping: localModels, by: { $0.checkmark })
                .map {  SectionModel(title: $0.key ? "Готово" : "Сделать", models: $0.value) }
                .sorted(by: { $0.title > $1.title })
            reloadTableView()
        } catch {
            showError(error)
        }
    }

    func reloadTableView() {
        var snapshot = NSDiffableDataSourceSnapshot<String, ToDoModel>()
        snapshot.appendSections(models.map { $0.title })
        for section in models {
            snapshot.appendItems(section.models, toSection: section.title)
        }
        dataSource.apply(snapshot)
    }

    func showLoginScreen() {
        let vc = storyboard!.instantiateViewController(withIdentifier: "LoginViewController")
        present(vc, animated: true)
    }
}
