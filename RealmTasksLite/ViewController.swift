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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        title = "My Tasks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}
