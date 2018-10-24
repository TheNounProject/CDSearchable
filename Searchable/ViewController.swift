//
//  ViewController.swift
//  Searchable
//
//  Created by Wesley Byrne on 8/15/17.
//  Copyright © 2017 WCBMedia. All rights reserved.
//

import Cocoa
import CollectionView

extension Int {
    
    static func random(in range: ClosedRange<Int>) -> Int {
        let min = range.lowerBound
        let max = range.upperBound
        return Int(arc4random_uniform(UInt32(1 + max - min))) + min
    }
}

extension Array {
    
    var random : Element {
        let idx = Int.random(in: 0...(self.count - 1))
        return self[idx]
        
    }
}

extension String {
    
    static let words = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum eget semper quam, eget posuere turpis. Nunc eu dui enim. Sed sed nisl sit amet tellus fringilla viverra. Suspendisse ex turpis, dignissim ut viverra vitae, lacinia ut magna. Ut nibh neque, vulputate vel varius sollicitudin, lobortis vulputate neque. Nulla eu dignissim metus. Etiam dolor est, congue eget semper id, scelerisque sit amet erat. Maecenas lacinia quam turpis, non hendrerit libero lobortis sagittis. Donec blandit egestas metus at imperdiet. Aliquam dignissim risus sit amet suscipit vestibulum. Duis porta fermentum enim ut maximus. Proin consequat ligula nibh, vitae lacinia risus malesuada at. Curabitur rhoncus ligula interdum nisl pretium, at rutrum turpis convallis. Donec eget ultricies quam. Nulla posuere sodales tellus, vitae scelerisque felis venenatis et. Integer aliquam consectetur mollis. Morbi porta, turpis ut aliquet interdum, nibh mi cursus nisl, vitae placerat ipsum metus at tellus. Mauris risus velit, accumsan eu enim in, dictum rutrum tellus. Aliquam erat volutpat. Proin porttitor erat vel tellus cursus, eget maximus dui imperdiet. Suspendisse eget eleifend felis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Cras suscipit augue sodales arcu congue molestie id ut lorem. Aliquam in dui tempus, elementum augue nec, egestas.".components(separatedBy: " ").map { (str) -> String in
        return str.trimmingCharacters(in: CharacterSet(charactersIn: " .,"))
    }

    
    static var randomWord : String {
        return words.random
    }
    
}



class ViewController: NSViewController, NSTextViewDelegate, CollectionViewDataSource {

    @IBOutlet weak var collectionView: CollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = CollectionViewListLayout()
        layout.itemHeight = 40
        layout.sectionInsets.top = 12
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        
        
        collectionView.register(class: ListCell.self, forCellWithReuseIdentifier: "ListCell")
        
        
        let moc = AppDelegate.current.persistentContainer.viewContext
        
        moc.perform {
            var now = CACurrentMediaTime()
//            for idx in 0..<10 {
//                print("Created \(idx) thingers")
//                Book.create(in: moc)
//            }
//            AppDelegate.current.saveAction(nil)
//            print("created 1000 books in \(CACurrentMediaTime() - now)")
            
            now = CACurrentMediaTime()
            
            try! SearchTerm.buildIndexes(for: ["Book", "Chapter", "Page"], in: moc)
            AppDelegate.current.saveAction(nil)
            print("created indexes in \(CACurrentMediaTime() - now)")
        }
        
        
        
    }

    
    @IBOutlet weak var textField: NSTextField!
    override func controlTextDidChange(_ obj: Notification) {
        
        self.completions.removeAll()
        
        let str = textField.stringValue
        let moc = AppDelegate.current.persistentContainer.viewContext
        
        var now = CACurrentMediaTime()
        var completions = SearchTerm.completions(str, from: moc)
        
        var titles = [Completion]()
        var genres = [Completion]()
        var keywords = [Completion]()
        
        completions.sort { (s1, s2) -> Bool in
            return s1.count > s2.count
        }
        for c in completions {
            switch c.category {
            case SearchTerm.Category.genre: genres.append(c)
            case SearchTerm.Category.title: titles.append(c)
            case SearchTerm.Category.keyword: keywords.append(c)
            default: break;
            }
        }
        
        if titles.count > 0 {
            self.completions.append(titles)
        }
        if genres.count > 0 {
            self.completions.append(genres)
        }
        if keywords.count > 0 {
            self.completions.append(keywords)
        }
        
        print("\(titles.count) Titles")
        print("\(genres.count) Genres")
        print("\(keywords.count) Keywords")
        print("Found \(completions.count) completions in \(CACurrentMediaTime() - now)")
        
        self.collectionView.reloadData()
        
//        now = CACurrentMediaTime()
//        let objects = SearchTerm.objects(matching: str, from: moc)
//        print("Found \(objects.count) objects in \(CACurrentMediaTime() - now)")
    }
    
    var completions = [[Completion]]()

    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return completions.count
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(5, completions[section].count)
    }
    
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
     
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as! ListCell
        if !cell.reused {
            cell.style = .basicImage
        }
        
        let completion = completions[indexPath._section][indexPath._item]
        
        if completion.category == .title {
            cell.imageView.image = #imageLiteral(resourceName: "book")
        }
        else if completion.category == .keyword {
            cell.imageView.image = #imageLiteral(resourceName: "page")
        }
        else if completion.category == .genre {
            cell.imageView.image = #imageLiteral(resourceName: "chapter")
        }
        
        cell.titleLabel.stringValue = "\(completion.term) (\(completion.count))"
        
        return cell
    }

}

