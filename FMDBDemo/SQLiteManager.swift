//
//  SQLiteManager.swift
//  FMDBDemo
//
//  Created by allen_zhang on 2019/4/10.
//  Copyright © 2019 com.mljr. All rights reserved.
//

import Foundation
import FMDB

class SQLiteManager: NSObject {
  
    private static let manger: SQLiteManager = SQLiteManager()
    class func shareManger() -> SQLiteManager {
        return manger
    }
    private  override init() {
    }
    private let dbName = "test.db"
    lazy var dbURL: URL = {
        let fileURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(dbName)
        print(fileURL)
        return fileURL
    }()
   
    lazy var db: FMDatabase = {
        let database = FMDatabase(url: dbURL)
        return database
    }()
    
    lazy var dbQueue: FMDatabaseQueue? = {
        let databaseQueue = FMDatabaseQueue(url: dbURL)
        return databaseQueue
    }()
}
