# EMStore

[![CI Status](http://img.shields.io/travis/eberl_ma@gmx.at/EMStore.svg?style=flat)](https://travis-ci.org/eberl_ma@gmx.at/EMStore)
[![Version](https://img.shields.io/cocoapods/v/EMStore.svg?style=flat)](http://cocoapods.org/pods/EMStore)
[![License](https://img.shields.io/cocoapods/l/EMStore.svg?style=flat)](http://cocoapods.org/pods/EMStore)
[![Platform](https://img.shields.io/cocoapods/p/EMStore.svg?style=flat)](http://cocoapods.org/pods/EMStore)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Xcode 9.4.1
Swift 5.0

## New In 1.6.0

* Added Cloud Kit Support

## New In 1.5.0

* Update Swift 5
* Fix relationship between models did not work

## New In 1.3.2

Fix store coordinator with iOS9 and lower

## New In 1.3.1

Reverted the throws block but a default sql file path url is being provided, if you won't provide any

## New In 1.3.0

If you won't enter a sql file, it will be provided for you. 
This is the actual implementation:

```guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
.userDomainMask, true).first else {
    throw SqlFile.filePathNotFound
}
return URL(fileURLWithPath: path).appendingPathComponent("content.sqlite")
```
Eventually if it can't be created, it throws an error.


## New In 1.2.0

You can now observe when a value has been inserted/added, removed, moved or updated.
All you have to do is to change the line in your Store Protocol from  ```var model: Observable<[Entry]>? { get }```  to  ```var entities: ManagedObjectObservable<[Entry]>? { get }``` or simply access the stores entitities with the parameter ```entities```. Of course you can still observe the complete entities with 
```onValueChanged { allEntities in ... }```

Here is an example.

```swift
    override func viewDidLoad() {
        super.viewDidLoad()

        //..
        store.entries?.onItemAdded { entity, indexPath in
            //... entity has been added
        }
        store.entries?.onItemRemoved { entity, indexPath in
            //... entity has been removed
        }
        store.entries?.onItemUpdated { entity, indexPath in
            //... entity has been updated
        }
        store.entries?.onItemMoved { entity, from, to in
            //... entity has been moved
        }
    }
```

## Installation

EMStore is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EMStore'
```

Define a store and implement it like follows. The "Model" is your xcdatamodeld file name. If this is not the same, your app will enventually crash. So be aware.
```swift
protocol EntryStore {
    var model: Observable<[Entry]>? { get }
    var new: Entry? { get }
    func add(model: Entry)
    func remove(model: Entry)
}

final class DefaultEntryStore: ManagedObjectStore<Entry>, EntryStore {
    init() {
        super.init(storage: SqliteStorage<Entry>("Model"),
        predicate: nil,
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    }
}
```

Now setup the store just like follows
```swift
let store: EntryStore = DefaultEntryStore()
```

To access the content of a store is farely easy
```swift
let fetched content = store.entries?.value
```

To add a new content to a store is again very easy
```swift
guard let entry = store.new else {
    return
}

entry.date = NSDate()
store.add(model: entry)
```

And last but not least, we want to be notified, whenever something has been been added or removed. Therefore we use the observeable value property. Use the closure and get notified whenever something may have changed. We may provide more closures in the future to get notified if one entry has been added.
```swift
override func viewDidLoad() {
    super.viewDidLoad()

    //..
    store.entries?.onValueChanged { _ in
        //... update the table- or collectionview .. or what ever you want to do with the content
    }
}
```

Looking forward for some feedback :)

## Author

Martin Eberl, eberl_ma@gmx.at

## License

EMStore is available under the MIT license. See the LICENSE file for more info.
