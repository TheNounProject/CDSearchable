//
//  Chapter.swift
//  Searchable
//
//  Created by Wesley Byrne on 8/15/17.
//  Copyright © 2017 nounproject. All rights reserved.
//

import Foundation
import CoreData


class Chapter : NSManagedObject, Searchable {

    
    @NSManaged public var chapterIndex: NSNumber
    @NSManaged public var pageCount: NSNumber
    @NSManaged public var title: String
    @NSManaged public var book: Book
    @NSManaged public var pages: Page
    @NSManaged public var needsIndex: Bool
    
    static let entityName: String = "Chapter"
    static var indexedKeys: [String] { return ["title"] }
    
    var searchIndexes: Set<SearchTerm.Index> {
        return Set([SearchTerm.Index(category: .title, term: self.title)])
    }
    
    override public func willSave() {
        super.willSave()
        let needs = _needsIndex
        if needsIndex != needs {
            self.needsIndex = needs
        }
    }   
}


class Page : NSManagedObject, Searchable {
    
    @NSManaged public var pageInChapter: NSNumber
    @NSManaged public var pageIndex: NSNumber
    @NSManaged public var title: String
    @NSManaged public var book: Book
    @NSManaged public var keywords: String
    @NSManaged public var chapter: Chapter
    @NSManaged public var needsIndex: Bool
    
    static let entityName: String = "Page"
    static var indexedKeys: [String] { return ["title", "keywords"] }
    
    var searchIndexes: Set<SearchTerm.Index> {
        var data = Set([SearchTerm.Index(category: .title, term: self.title)])
        for t in keywords.components(separatedBy: ",") {
            let k = SearchTerm.Index(category: .keyword,
                                     term: t.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            data.insert(k)
        }
        return data
    }
    
    override public func willSave() {
        super.willSave()
        let needs = _needsIndex
        if needsIndex != needs {
            self.needsIndex = needs
        }
    }
    
}
