//
//  Object.swift
//  Searchable
//
//  Created by Wesley Byrne on 8/15/17.
//  Copyright © 2017 WCBMedia. All rights reserved.
//

import Foundation
import CoreData



extension SearchTerm.Category {
    static let entity = SearchTerm.Category(0)
    static let title = SearchTerm.Category(1)
    static let keyword = SearchTerm.Category(2)
    static let genre = SearchTerm.Category(3)
}

extension Notification.Name {
    
}


public class Book : NSManagedObject, Searchable {
    
    @NSManaged var title : String
    @NSManaged var keywords : String
    @NSManaged var pageCount : NSNumber
    @NSManaged var chapterCount : NSNumber
    @NSManaged var released : Date
    @NSManaged var genre : String
    
    @NSManaged var pages : Set<Page>
    @NSManaged var chapters : Set<Chapter>
    
    @NSManaged var needsIndex : Bool
    
    static let entityName: String = "Book"
    static var indexedKeys: [String] { return ["title", "keywords"] }

    var searchIndexes: Set<SearchTerm.Index> {
        var data = Set([
            SearchTerm.Index(category: .title, term: self.title),
            SearchTerm.Index(category: .genre, term: self.genre)
                ])
        
        for t in keywords.components(separatedBy: ",") {
            let k = SearchTerm.Index(category: .keyword,
                              term: t.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            data.insert(k)
        }
        return data
    }
    
    
    static let genres = ["Fiction", "Drama", "Non-Fiction", "Culture", "Comedy", "Horror"]
    
    static func create(in moc: NSManagedObjectContext) {
        
        let book = NSEntityDescription.insertNewObject(forEntityName: "Book", into: moc) as! Book
        book.title = [String.randomWord, String.randomWord, String.randomWord].joined(separator: " ")
        book.keywords = [String.randomWord, String.randomWord, String.randomWord].joined(separator: ",")
        book.genre = genres.random
        
        var pageIndex = 0
        
            book.chapterCount = NSNumber(value: Int.random(in: 5...20))
        
        for cIdx in 0...book.chapterCount.intValue {
            let chapter = NSEntityDescription.insertNewObject(forEntityName: "Chapter", into: moc) as! Chapter
            chapter.book = book
            
            chapter.chapterIndex = NSNumber(value: cIdx)
            chapter.title = [String.randomWord, String.randomWord, String.randomWord].joined(separator: " ")
            
            chapter.pageCount = NSNumber(value: Int.random(in: 5...100))
            
            for pIdx in 0...chapter.pageCount.intValue {
                let page = NSEntityDescription.insertNewObject(forEntityName: "Page", into: moc) as! Page
                page.pageIndex = NSNumber(value:pIdx)
                page.pageIndex = NSNumber(value:pageIndex)
                page.book = book
                page.keywords = [String.randomWord, String.randomWord, String.randomWord, String.randomWord, String.randomWord, String.randomWord, String.randomWord].joined(separator: ",")
                page.chapter = chapter
                page.title = [String.randomWord, String.randomWord, String.randomWord].joined(separator: " ")
                pageIndex += 1
            }
        }
        
        book.pageCount = NSNumber(value: pageIndex)
        book.released = Date()
    }
    
    override public func willSave() {
        super.willSave()
        let needs = _needsIndex
        if needsIndex != needs {
            self.needsIndex = needs
        }
    }
    
    
}
