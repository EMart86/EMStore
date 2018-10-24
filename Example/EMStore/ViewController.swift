//
//  ViewController.swift
//  EMStore
//
//  Created by eberl_ma@gmx.at on 08/15/2017.
//  Copyright (c) 2017 eberl_ma@gmx.at. All rights reserved.
//

import UIKit

class StoreProvider {
    lazy var storeProvider: EntryStore? = {
       return DefaultEntryStore()
    }()
}

class ViewController: UITableViewController {
    
    let provider = StoreProvider()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        provider.storeProvider?.models?.onValueChanged {[weak tableView = self.tableView] _ in
            tableView?.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCreatePressed(_ sender: Any) {
        guard let entry = provider.storeProvider?.new else {
            return
        }
        
        entry.date = Date()
        provider.storeProvider?.add(model: entry)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return provider.storeProvider!.models?.value?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "")
        cell.textLabel?.text = String(describing: provider.storeProvider?.models?.value?[indexPath.row].date)
        return cell
    }
}

