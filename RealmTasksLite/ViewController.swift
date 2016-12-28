//
//  ViewController.swift
//  RealmTasksLite
//
//  Created by William L. Marr III on 2016/12/28.
//  Copyright © 2016 William L. Marr III. All rights reserved.
//

import UIKit
import RealmSwift

// MARK: Model

final class Task: Object {
    dynamic var text = ""
    dynamic var completed = false
}

final class TaskList: Object {
    dynamic var text = ""
    dynamic var id = ""
    let items = List<Task>()

    override static func primaryKey() -> String? {
        return "id"
    }
}

class ViewController: UITableViewController {
    var items = List<Task>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // FIXME: test data to be removed at some later point...
        items.append(Task(value: ["text": "My First Task"]))
    }

    func setupUI() {
        title = "My Tasks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: UITableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.text
        cell.textLabel?.alpha = item.completed ? 0.5 : 1
        return cell
    }
}
