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
       return try? DefaultEntryStore()
    }()
    
    lazy var cloudProvider: EntryStore? = {
        return try? CloudEntryStore()
    }()
}

class ViewController: UITableViewController {
    
    let provider = StoreProvider()
    private var itemHasBeenUpdated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        provider.storeProvider?.entities?.onItemAdded { value, _ in
            print("\(value) has been added")
        }
        
        provider.storeProvider?.entities?.onItemRemoved { value, _ in
            print("\(value) has been removed")
        }
        
        provider.storeProvider?.entities?.onItemUpdated { value, _ in
            print("\(value) has been updated")
        }
        
        provider.storeProvider?.entities?.onValueChanged {[weak tableView = self.tableView] _ in
            tableView?.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCreatePressed(_ sender: Any) {
        guard let item = provider.storeProvider?.entities?.value?.first else {
            insertNewItem()
            itemHasBeenUpdated = false
            return
        }
        if !itemHasBeenUpdated {
            item.date = Date()
            provider.storeProvider?.commit()
            itemHasBeenUpdated = true
        } else {
            try? provider.storeProvider?.remove(model: item)
            itemHasBeenUpdated = false
        }
    }
    
    private func insertNewItem() {
        guard let entry = provider.storeProvider?.new else {
            return
        }
        
        entry.date = Date()
        try? provider.storeProvider?.add(model: entry)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return provider.storeProvider!.entities?.value?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "")
        cell.textLabel?.text = String(describing: provider.storeProvider?.entities?.value?[indexPath.row].date)
        return cell
    }
}

