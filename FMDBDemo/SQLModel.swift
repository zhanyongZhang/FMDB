//
//  SQLModel.swift
//  FMDBDemo
//
//  Created by allen_zhang on 2019/4/11.
//  Copyright © 2019 com.mljr. All rights reserved.
//

import Foundation

protocol SQLModelProtocol {
    
}

@objcMembers
class SQLModel: NSObject, SQLModelProtocol {
    
    internal var table = ""
    
    private static var verified = [String : Bool]()
    
    required override init() {
        super.init()
        
        self.table = type(of: self).table
        let verified = SQLModel.verified[self.table]
        if verified == nil || !verified! {
            let db = SQLiteManager.shareManger().db
            var sql = "CREATE TABLE IF NOT EXISTS \(table) ("
            let cols = values()
            var first = true
            for col in cols {
                
                if first {
                    
                    first = false
                    sql += getColumnSQL(column: col)
                } else {
                    sql += "," + getColumnSQL(column: col)
                }
            }
            sql += ")"
            if db.open() {
                db.executeUpdate(sql, withArgumentsIn: [])
                SQLModel.verified[table] = true
                print("\(table) 表自动创建成功")
            }
        }
        
    }
    
    private func getColumnSQL(column:(key: String, value: Any)) -> String {
        let key = column.key
        let val = column.value
        var sql = "'\(key)'"
        if val is Int {
            
            sql += "INTEGER"
            if key == primaryKey() {
                sql += " PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE"
            } else {
                sql += " DEFAULT \(val)"
            }
        } else {
            
            if val is Float || val is Double {
                sql += "REAL DEFAULT \(val)"
            } else if val is Bool {
                sql += "BOOLEAN DEFAULT " + ((val as! Bool) ? "1" : "0")
            } else if val is Date {
                sql += "DATE"
            } else if val is NSData {
                sql += "BLOB"
            } else {
                sql += "TEXT"
            }
            if key == primaryKey() {
                sql += " PRIMARY KEY NOT NULL UNIQUE"
            }
        }
        return sql
    }
    
    func  primaryKey() -> String {
        return "id"
    }
    func ignoredKeys() -> [String] {
        return []
    }
    static var table: String {
        return "\(classForCoder())"
    }
    internal func values() -> [String : Any] {
        var res = [String : Any]()
        let obj = Mirror(reflecting: self)
        processMirror(obj: obj, results: &res)
        getValues(obj: obj.superclassMirror, results: &res)
        return res
    }
    
    private func getValues(obj: Mirror?, results: inout [String:Any]){
        guard let obj = obj  else {
            return
        }
        processMirror(obj: obj, results: &results)
        getValues(obj: obj.superclassMirror, results: &results)
    }
    
    private func processMirror(obj: Mirror, results: inout [String: Any]) {
        
        for  (_ , attr) in obj.children.enumerated() {
            
            if let name = attr.label {
                if name == "table" || name == "db" {
                    continue
                }
                if ignoredKeys().contains(name) || name.hasSuffix(".storage") {
                    continue
                }
                results[name] = unwrap(attr.value)
            }
        }
    }
    
    private func unwrap(_ any: Any) -> Any {
        let mi = Mirror(reflecting: any)
        if mi.displayStyle != .optional {
            return any
        }
        if mi.children.count == 0 { return any }
        let (_ , some) = mi.children.first!
        return some
    }
    
    @discardableResult
    class func remove(filter: String) -> Bool {
        
        let db = SQLiteManager.shareManger().db
        var sql = "DELETE FROM \(table)"
        if !filter.isEmpty {
            sql += " WHERE \(filter)"
        }
        if db.open() {
            return db.executeUpdate(sql, withArgumentsIn: [])
        } else {
            return false
        }
    }
    
    class func count(filter: String = "") -> Int {
        
        let db = SQLiteManager.shareManger().db
        var sql = "SELECT COUNT(*) AS count FROM \(table)"
        if !filter.isEmpty {
            sql += " WHERE \(filter)"
        }
        if db.open() {
            if  let res =  db.executeQuery(sql, withArgumentsIn: []){
                if res.next() {
                    return Int(res.int(forColumn: "count"))
                }
            }
        } else {
            return 0
        }
        return 0
    }
    @discardableResult
    func save() -> Bool {
        
        let key = primaryKey()
        let data = values()
        var insert = true
        let db = SQLiteManager.shareManger().db
        
        if let rid = data[key] {
            var val = "\(rid)"
            if rid is String {
                val = "'\(rid)'"
            }
            let sql = "SELECT COUNT(*) AS count FROM \(table) "
                + "WHERE \(primaryKey())=\(val)"
            if db.open() {
                if  let res = db.executeQuery(sql, withArgumentsIn: []) {
                    if res.next() {
                        insert = res.int(forColumn: "count") == 0
                    }
                }
                
            }
        }
        
        let (sql, params) = getSQL(data: data, forInsert: insert)
        if db.open() {
            return db.executeUpdate(sql, withArgumentsIn: params ?? [])
        } else {
            return false
        }
    }
    
    @discardableResult
    func delete() -> Bool {
        
        let key = primaryKey()
        let data = values()
        let db = SQLiteManager.shareManger().db
        if let rid = data[key] {
            if db.open() {
                let sql = "DELETE FROM \(table) WHERE \(primaryKey())=\(rid)"
                return db.executeUpdate(sql, withArgumentsIn: [])
            }
        }
        return false
    }
    
    
    private func getSQL(data:[String:Any], forInsert:Bool = true)
        -> (String, [Any]?) {
            var sql = ""
            var params: [Any]? = nil
            
            if forInsert {
                sql = "INSERT INTO \(table)("
            } else {
                sql = "UPDATE \(table) SET "
            }
            let pkey = primaryKey()
            var wsql = ""
            var rid: Any?
            var first = true
            for (key, val) in data {
                
                if pkey == key {
                    if forInsert {
                        if val is Int && (val as! Int) == -1 {
                            continue
                        }
                    } else {
                        wsql += " WHERE " + key + " = ?"
                        rid = val
                        continue
                    }
                }
                if first && params == nil {
                    params = [AnyObject]()
                }
                if forInsert {
                    sql += first ? "\(key)" : ", \(key)"
                    wsql += first ? " VALUES (?" : ", ?"
                    params!.append(val)
                } else {
                    sql += first ? "\(key) = ?" : ", \(key) = ?"
                    params!.append(val)
                }
                first = false
            }
            if forInsert {
                sql += ")" + wsql + ")"
            } else if params != nil && !wsql.isEmpty {
                sql += wsql
                params!.append(rid!)
            }
            return (sql, params)
    }
}


extension SQLModelProtocol where Self: SQLModel {
    
    static func rowsFor(sql: String = "") -> [Self] {
        var result = [Self]()
        let tmp = self.init()
        let data = tmp.values()
        let db = SQLiteManager.shareManger().db
        let fsql = sql.isEmpty ? "SELECT * FROM \(table)" : sql
        
        if let res = db.executeQuery(fsql, withArgumentsIn: []) {
            while res.next() {
                let t = self.init()
                for (key, _) in data {
                    if let val = res.object(forColumn: key) {
                        t.setValue(val, forKey: key)
                    }
                }
                result.append(t)
            }
        } else {
            print("查询失败")
        }
        return result
    }
    static func rows(filter: String = "", order: String = "",
                     limit: Int = 0) -> [Self] {
        
        var sql = "SELECT * FROM \(table)"
        if !filter.isEmpty {
            sql += " WHERE \(filter)"
        }
        if !order.isEmpty {
            sql += " ORDER BY \(order)"
        }
        if limit > 0 {
            sql += " LIMIT 0, \(limit)"
        }
        return rowsFor(sql: sql)
    }
}
