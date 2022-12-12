//
//  DataSource.swift
//  Client
//
//  Created by Даниил Виноградов on 10.12.2022.
//

import UIKit


public protocol Identifiable: Hashable {
    var identity: AnyHashable { get }
}

public struct UITableViewComparableDataSource<SectionIdentifierType: Hashable, ItemType: Identifiable> {
    private struct ItemIdentifierType: Hashable, Identifiable {
        var value: ItemType
        init(_ value: ItemType) {
            self.value = value
        }

        var identity: AnyHashable {
            return value.identity
        }

        static func == (_ a: ItemIdentifierType, _ b: ItemIdentifierType) -> Bool {
            return a.identity == b.identity
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(identity)
        }
    }

    private let dataSource: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    private let tableView: UITableView
    private let cellUpdater: CellUpdater

    public typealias CellProvider = (UITableView, IndexPath, ItemType) -> UITableViewCell?
    public typealias CellUpdater = (UITableView, UITableViewCell, IndexPath, ItemType) -> Void

    public init(tableView: UITableView, cellProvider: @escaping CellProvider, cellUpdater: @escaping CellUpdater) {
        self.tableView = tableView
        self.dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            guard let cell = cellProvider(tableView, indexPath, item.value) else { return nil }
            cellUpdater(tableView, cell, indexPath, item.value)
            return cell
        }
        self.tableView.dataSource = self.dataSource
        self.cellUpdater = cellUpdater
    }

    public func apply(_ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemType>, animatingDifferences: Bool = true) {
        // the items currently visible
        // we shouldn't need to update anything offscreen since it will get a new cell even if it moves into view
        guard let visibleItemIdentifiers = tableView.indexPathsForVisibleRows?
            .compactMap({ dataSource.itemIdentifier(for: $0) })
        else { return }

        // the item identifiers that are not causing a new cell to be created, but have an updated value
        var updatedItemIdentifiers: [ItemIdentifierType] = []

        // we need to convert the snapshot types, even though this is sort of a no-op
        var converted = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        for section in snapshot.sectionIdentifiers {
            converted.appendSections([section])
            let itemIdentifiers = snapshot.itemIdentifiers(inSection: section).map({ ItemIdentifierType($0) })

            // any of these items that are in the visibleItemIdentifiers (defined by identity) but have a different value
            updatedItemIdentifiers.append(contentsOf: itemIdentifiers
                .filter({ itemIdentifier in
                    visibleItemIdentifiers.first(where: { $0 == itemIdentifier })?.value != itemIdentifier.value
                }))

            converted.appendItems(itemIdentifiers, toSection: section)
        }

        let updates = {
            // only updating the cells that have changed values and are on screen
            // everything else is either unchanged or will get a complete cell refresh
            for itemIdentifier in updatedItemIdentifiers {
                guard let indexPath = self.dataSource.indexPath(for: itemIdentifier) else { continue }
                guard let cell = self.tableView.cellForRow(at: indexPath) else { continue }

                self.cellUpdater(self.tableView, cell, indexPath, itemIdentifier.value)
            }
        }

        if animatingDifferences {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }

        self.dataSource.apply(converted, animatingDifferences: animatingDifferences)
    }
}
