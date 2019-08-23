//
//  PinLocation.swift
//  Map
//
//  Created by RS on 2019/07/05.
//  Copyright © 2019 com.litech. All rights reserved.
//

import Foundation
import RealmSwift

class Pin: Object {
    static let realm = try! Realm()
    
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var caption = ""
    @objc dynamic var latitude:Double = 0.0
    @objc dynamic var lognitude: Double = 0.0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func lastId() -> Int {
        if let pin = realm.objects(Pin.self).last {
            return pin.id + 1
        } else {
            return 0
        }
    }
    
    static func create() -> Pin {
        let pin = Pin()
        pin.id = lastId()
        return pin
    }
    
    func save() {
        try! Pin.realm.write {
            realm?.add(self)
        }
    }
    
    static func loadAll() -> [Pin] {
        let pins = realm.objects(Pin.self).sorted(byKeyPath: "id")
        var array: [Pin] = []
        for pin in pins {
            array.append(pin)
        }
        
        return array
    }
    
    static func loadOne(id: Int) -> Pin {
        let pinResult = realm.objects(Pin.self).filter("id = \(id)")
        let pin = pinResult[0]
        return pin
    }
}
