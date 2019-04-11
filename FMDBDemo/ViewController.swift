//
//  ViewController.swift
//  FMDBDemo
//
//  Created by allen_zhang on 2019/4/9.
//  Copyright © 2019 com.mljr. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        create()
        query()
    }
    func create() {
        for i in 1..<11 {
            let user = User()
            user.name = "ALLEN\(i)"
            user.age = 100 + i
            user.save()
        }
    }
    
    func query() {
        
        let users = User.rows()
        for user in users {
            print(user.uid, user.name, user.age)
        }
    }
    //批量插入
    func insertQueueData() {
        
        if let queue = SQLiteManager.shareManger().dbQueue {
            queue.inTransaction { db, rollback in
                
                do {
                    for i in 0..<10 {
                        try db.executeUpdate("INSERT INTO User (name, age) VALUES (?,?);", values: ["allen",i])
                    }
                    print("success")
                }catch {
                    print("faile")
                    rollback.pointee = true
                }
            }
        }
    }
    
    func createTable() {
        let sql = "CREATE TABLE IF NOT EXISTS User( \n" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, \n" +
            "name TEXT, \n" +
            "age INTEGER \n" +
        "); \n"
        let db = SQLiteManager.shareManger().db
        if db.open() {
            
            if db.executeUpdate(sql, withArgumentsIn: []) {
                
                print("create success")
            } else {
                print("create faile")
            }
        }
    }
    func insertData() {
        let sql = "INSERT INTO User (name, age) VALUES ('hangge', 100);"
        
        let db = SQLiteManager.shareManger().db
        if db.open() {
            if db.executeUpdate(sql, withArgumentsIn: []){
                print("插入成功")
            }else{
                print("插入失败")
            }
        }
        db.close()
    }
    
    func updateData() {
        let sql = "UPDATE User set name = 'hangge.com' WHERE id = 2;"
        
        // 执行SQL语句
        let db = SQLiteManager.shareManger().db
        if db.open() {
            if db.executeUpdate(sql, withArgumentsIn: []){
                print("更新成功")
            }else{
                print("更新失败")
            }
        }
        db.close()
    }
}

