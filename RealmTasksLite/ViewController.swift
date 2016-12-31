//
//  ViewController.swift
//  RealmTasksLite
//
//  Created by William L. Marr III on 2016/12/28.
//  Copyright © 2016 William L. Marr III. All rights reserved.
//
// swiftlint:disable variable_name force_try

import UIKit
import RealmSwift

// MARK: Model

/// The `Task` class represents a *single* task.
final class Task: Object {
    /// The task's text.
    dynamic var text = ""
    /// Boolean indicating whether the task is complete or not.
    dynamic var completed = false
}

/// The `TaskList` class represents a *list* of `Task` objects.
final class TaskList: Object {
    /// The task list's name.
    dynamic var text = ""
    /// The task list's ID.
    dynamic var id = ""
    /// The list of `Task` objects for this task list.
    let items = List<Task>()

    /**
        The `primaryKey()` method is used to return the string representation of
        the property that is used as the primary key for the `TaskList` Realm object.

        # Note #
        This method is declared as `static`, and can therefore only be called through the class itself.
    */
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: Table View Controller

/**
    View controller for the main (and only) scene which contains a table view.
*/
class ViewController: UITableViewController {
    // MARK: Properties

    /// List of `Task` objects.
    var items = List<Task>()
    /// Notifies the app when the Realm database is modified by another user.
    var notificationToken: NotificationToken!
    /// Realm database object.
    var realm: Realm!

    // MARK: Overrides

    /// Called after the view has been loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRealm()
    }

    // MARK: Methods

    /**
        The setup procedure for the app's user interface.

        - SeeAlso: `setupRealm()`
        - Returns: Void
    */
    func setupUI() {
        title = "My Tasks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(add))
        navigationItem.leftBarButtonItem = editButtonItem
    }

    /**
        This sets up the connection to the Realm database.

        - SeeAlso: `setupUI()`
        - Returns: Void
    */
    func setupRealm() {
        // Log in existing user with username and password.
        let username = "billy"
        let password = "1234"

        SyncUser.logIn(with: .usernamePassword(username: username,
                                               password: password,
                                               register: false),
                       server: URL(string: "http://127.0.0.1:9080")!) { user, error in
            guard let user = user else {
                fatalError(String(describing: error))
            }

            DispatchQueue.main.async {
                // Open Realm
                let configuration = Realm.Configuration(
                    syncConfiguration: SyncConfiguration(user: user,
                                                         realmURL: URL(string: "realm://127.0.0.1:9080/~/realmtasks")!)
                )
                self.realm = try! Realm(configuration: configuration)

                // Show initial tasks
                func updateList() {
                    if self.items.realm == nil, let list = self.realm.objects(TaskList.self).first {
                        self.items = list.items
                    }
                    self.tableView.reloadData()
                }

                updateList()

                // Notify us when Realm changes.
                self.notificationToken = self.realm.addNotificationBlock { _ in
                    updateList()
                }
            }
        }
    }

    /**
        Presents an alert popup for creating a new task
        when the '+' button is tapped on the main scene.

        - Returns: Void
     */
    func add() {
        let alertController = UIAlertController(title: "New Task", message: "Enter Task Name", preferredStyle: .alert)
        var alertTextField: UITextField!
        alertController.addTextField { textField in
            alertTextField = textField
            textField.placeholder = "Task Name"
        }
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let text = alertTextField.text, !text.isEmpty else {
                return
            }

            let items = self.items
            try! items.realm?.write {
                items.insert(Task(value: ["text": text]), at: items.filter("completed = false").count)
            }
        })

        present(alertController, animated: true, completion: nil)
    }

    /**
        `deinit` is used to make sure that the notification token is deallocated.
    */
    deinit {
        notificationToken.stop()
    }

    // MARK: UITableView

    /**
        Method to get the number of rows for a specific section of the table view.

        - Returns: The number of rows for the specified section of the table view.
    */
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    /**
        Method to get the cell at a specific row of the table view.

        - Returns: The cell object for the specified row of the table view.
    */
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.text
        cell.textLabel?.alpha = item.completed ? 0.5 : 1
        return cell
    }

    /**
        Method for handling moving and rearranging rows in the table view.

        - Returns: Void
    */
    override func tableView(_ tableView: UITableView,
                            moveRowAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
        try! items.realm?.write {
            items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        }
    }

    /**
        Method to commit any changes made to a cell to the data model.

        - Returns: Void
    */
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! realm.write {
                let item = items[indexPath.row]
                realm.delete(item)
            }
        }
    }

    /**
        Method for handling when a row is tapped in the table view.

        - Returns: Void
    */
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        try! item.realm?.write {
            item.completed = !item.completed
            let destinationIndexPath: IndexPath
            if item.completed {
                // move cell to bottom
                destinationIndexPath = IndexPath(row: items.count - 1, section: 0)
            } else {
                // move cell just above the first completed item
                let completedCount = items.filter("completed = true").count
                destinationIndexPath = IndexPath(row: items.count - completedCount - 1, section: 0)
            }
            items.move(from: indexPath.row, to: destinationIndexPath.row)
        }
    }
}
