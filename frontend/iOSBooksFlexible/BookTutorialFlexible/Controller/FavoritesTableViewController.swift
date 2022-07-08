//
//  FavoritesTableViewController.swift
//  BookTutorialFlexible
//
//  Created by Josman Pedro Pérez Expósito on 8/7/22.
//

import UIKit
import RealmSwift

protocol RemoveFavoriteProtocol {
    func didRemoveFavorite(index: Int)
}

class FavoritesTableViewController: UITableViewController {
    
    var user: User?
    var books: Results<Book>?
    var delegate: RemoveFavoriteProtocol?
    static let cellIdentifier = "favCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.register(UINib(nibName: BookCell.nibName, bundle: nil), forCellReuseIdentifier: BookCell.reuseIdentifier)

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let user = user else { return 0 }
        return user.favoriteBooks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//            guard let user = user, let books = books else { return UITableViewCell() }
//            let _books = books.where {
//                ($0._id == user.favoriteBooks[indexPath.row])
//            }
//            guard let book = _books.first, let title = book.volumeInfo?.title else { return UITableViewCell() }
//            let cell = tableView.dequeueReusableCell(withIdentifier: FavoritesTableViewController.cellIdentifier, for: indexPath)
//            cell.textLabel?.text = title
//            cell.selectionStyle = .none
//            return cell
        guard let user = user, let books = books, let cell = tableView.dequeueReusableCell(withIdentifier: BookCell.reuseIdentifier, for: indexPath) as? BookCell else { return UITableViewCell() }
        let _books = books.where {
            ($0._id == user.favoriteBooks[indexPath.row])
        }
        guard let _book = _books.first else { return UITableViewCell() }
        // Show the books name text on the left.
        cell.configureCell(book: _book)
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            delegate?.didRemoveFavorite(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

}
