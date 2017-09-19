//
//  ViewController.swift
//  EMStore
//
//  Created by eberl_ma@gmx.at on 08/15/2017.
//  Copyright (c) 2017 eberl_ma@gmx.at. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    let store: EntryStore = DefaultEntryStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        store.entries?.onValueChanged(closure: {[weak tableView = self.tableView] _ in
            tableView?.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCreatePressed(_ sender: Any) {
        guard let entry = store.new else {
            return
        }
        
        entry.date = NSDate()
        store.add(model: entry)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.entries?.value?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "")
        cell.textLabel?.text = String(describing: store.entries?.value?[indexPath.row].date)
        return cell
    }
}

