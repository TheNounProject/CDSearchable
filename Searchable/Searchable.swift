//
//  Searchable.swift
//  Searchable
//
//  Created by Wesley Byrne on 8/15/17.
//  Copyright © 2017 WCBMedia. All rights reserved.
//

import Foundation
import CoreData



protocol Searchable : class {
    var searchIndexes : Set<SearchTerm.Index> { get }
    var searchIndexIdentifier : String { get }
    var needsIndex : Bool { get set }
    
    static var entityName : String { get }
    static var indexedKeys : [String] { get }
}


extension Searchable where Self:NSManagedObject {
    
    var searchIndexIdentifier : String {
        return self.objectID.uriRepresentation().absoluteString
    }
    
    var _needsIndex : Bool {
        if self.objectID.isTemporaryID { return true }
        
        for k in type(of: self).indexedKeys {
            if self.changedValues()[k] != nil { return true }
        }
        return false
    }
    
}


extension NSExpressionDescription {
    
    convenience init(name: String, expression: NSExpression, resultType: NSAttributeType) {
        self.init()
        self.name = name
        self.expression = expression
        self.expressionResultType = resultType
    }
    
    
    convenience init(name: String, keyPath: String, resultType: NSAttributeType) {
        self.init()
        self.name = name
        self.expression = NSExpression(forKeyPath: keyPath)
        self.expressionResultType = resultType
    }
}


typealias Completion = SearchTerm.Completion

class SearchTerm : NSManagedObject {
    @NSManaged var term : String
    @NSManaged var cleanTerm : String
    @NSManaged var category : NSNumber
    @NSManaged var objectType : String
    @NSManaged var objectIdentifier : String
    
    
    public struct Category : RawRepresentable, Equatable, Hashable {
        
        public typealias RawValue = Int
        public let rawValue: Int
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        public init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public var hashValue: Int { return rawValue }
        
        static func ==(lhs: Category, rhs: Category) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
    
    
    struct Index : Hashable {
        let category : Category
        let term : String
        
        var hashValue: Int {
            return "\(term)_\(category)".hashValue
        }
        
        static func ==(lhs: Index, rhs: Index) -> Bool {
            return lhs.category == rhs.category && lhs.term == rhs.term
        }
    }
    
    var index : Index {
        return Index(category: Category(self.category.intValue), term: self.term)
    }
    
    static func updateEntries(for object: Searchable, in moc: NSManagedObjectContext) {
        
        let req = NSFetchRequest<SearchTerm>(entityName: "SearchTerm")
        req.predicate = NSPredicate(format: "objectIdentifier = %@", object.searchIndexIdentifier)
        
        let terms = try! moc.fetch(req)
        
        var newTerms = object.searchIndexes
        
        for t in terms {
            guard newTerms.remove(t.index) != nil else {
                moc.delete(t)
                continue
            }
        }
        for t in newTerms {
            let new = NSEntityDescription.insertNewObject(forEntityName: "SearchTerm", into: moc) as! SearchTerm
            new.category = NSNumber(value: t.category.rawValue)
            new.term = t.term
            new.cleanTerm = t.term.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            new.objectType = type(of: object).entityName
            new.objectIdentifier = object.searchIndexIdentifier
        }
        object.needsIndex = false
    }
    
    
    static func buildIndexes(for entityNames: [String], in moc: NSManagedObjectContext) throws {
        
        var count = 0
        for e in entityNames {
            
            let req = NSFetchRequest<NSManagedObject>(entityName: e)
            req.predicate = NSPredicate(format: "needsIndex == YES")
            
            for obj in try moc.fetch(req) {
                if let s = obj as? Searchable {
                    print("Building index : \(count)")
                    SearchTerm.updateEntries(for: s, in: moc)
                    count += 1
                }
            }
        }
    }
    
    struct Completion {
        let term : String
        let count : Int
        let category : Category
    }
    
    static func completions(_ term: String, from moc: NSManagedObjectContext) -> [Completion] {
        
        let str = term.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        
        let req = NSFetchRequest<NSDictionary>(entityName: "SearchTerm")
        
        
        
        let countDesc = NSExpressionDescription(name: "count",
                                                expression: NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "objectIdentifier")]),
                                                resultType: NSAttributeType.integer64AttributeType)
        
        let termDesc = NSExpressionDescription(name: "term",
                                                 keyPath: "term",
                                                 resultType: .stringAttributeType)
        
        let categoryDesc = NSExpressionDescription(name: "category",
                                               keyPath: "category",
                                               resultType: .integer16AttributeType)
        req.resultType = NSFetchRequestResultType.dictionaryResultType
        req.propertiesToFetch = [countDesc, termDesc, categoryDesc]
        req.propertiesToGroupBy = [termDesc, categoryDesc]
        let pred = NSPredicate(format: "cleanTerm BEGINSWITH %@", str)
        
//        let words = term.components(separatedBy: " ")
//        if words.count > 0 {
//            for w in words {
//                pred = NSCompoundPredicate(orPredicateWithSubpredicates: [
//                    pred,
//                    NSPredicate(format: "cleanTerm BEGINSWITH %@", w)
//                    ])
//            }
//        }
        
        req.predicate = pred
        
        let results = try! moc.fetch(req)
        
        var res = [Completion]()
        for r in results {
            res.append(Completion(term: r["term"] as! String,
                                  count: r["count"] as! Int,
                                  category: Category(r["category"] as! Int)
            ))
        }
        
        return res
    }
    
    static func objects(matching term: String, from moc: NSManagedObjectContext) -> [Searchable] {
        let str = term.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        
        let req = NSFetchRequest<SearchTerm>(entityName: "SearchTerm")
        req.predicate = NSPredicate(format: "cleanTerm CONTAINS %@", str)
        
        let terms = try! moc.fetch(req)
        
        var objects = [Searchable]()
        for t in terms {
            let url = URL(string: t.objectIdentifier)!
            
            if let id = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
                let obj = try! moc.existingObject(with: id) as? Searchable {
                objects.append(obj)
            }
        }
        return objects
    }
    
}
