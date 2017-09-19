# EMStore

[![CI Status](http://img.shields.io/travis/eberl_ma@gmx.at/EMStore.svg?style=flat)](https://travis-ci.org/eberl_ma@gmx.at/EMStore)
[![Version](https://img.shields.io/cocoapods/v/EMStore.svg?style=flat)](http://cocoapods.org/pods/EMStore)
[![License](https://img.shields.io/cocoapods/l/EMStore.svg?style=flat)](http://cocoapods.org/pods/EMStore)
[![Platform](https://img.shields.io/cocoapods/p/EMStore.svg?style=flat)](http://cocoapods.org/pods/EMStore)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

EMStore is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EMStore'
```

Define a store and implement it like follows. The "Model" is your xcdatamodeld file name. If this is not the same, your app will enventually crash. So be aware.
```swift
protocol EntryStore {
var entries: Observable<[Entry]>? { get }
var new: Entry? { get }
func add(model: Entry)
func remove(model: Entry)
}

final class DefaultEntryStore: ManagedObjectStore<Entry>, EntryStore {

init() {
super.init(storage: SqliteStorage<Entry>("Model").createProvider(),
entity: Entry.self,
predicate: nil,
sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
}

var entries: Observable<[Entry]>? {
return models()
}

var new: Entry? {
return new()
}

func add(model: Entry) {
super.add(model: model)
}

func remove(model: Entry) {
super.remove(model: model)
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
store.entries?.onValueChanged(closure: {[weak tableView = self.tableView] _ in
//... update thee table- or collectionview .. or what ever you want to do with the content
})
}
```

Looking forward for some feedback :)

## Author

Martin Eberl, eberl_ma@gmx.at

## License

EMStore is available under the MIT license. See the LICENSE file for more info.
