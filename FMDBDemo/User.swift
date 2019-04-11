//
//  User.swift
//  FMDBDemo
//
//  Created by allen_zhang on 2019/4/11.
//  Copyright © 2019 com.mljr. All rights reserved.
//

import Foundation

class User: SQLModel {
    
    var uid: Int = -1
    var name: String = ""
    var age: Int = -1
    
    override func primaryKey() -> String {
        return "uid"
    }
}
