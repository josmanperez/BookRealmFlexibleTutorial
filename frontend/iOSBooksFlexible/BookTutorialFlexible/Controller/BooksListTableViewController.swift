//
//  BooksListTableViewController.swift
//  BookTutorialFlexible
//
//  Created by Josman Pedro Pérez Expósito on 10/6/22.
//

import UIKit
import RealmSwift
import Realm.RLMUser

class BooksListTableViewController: UITableViewController {
    
    static let loginSegue = "showLogin"
    static let showFavorites = "showFavorites"
    static let showSettings = "showSettings"
    
    var realm = try! Realm()
    var books: Results<Book>?
    var user: User?
    var notificationToken: NotificationToken?
    
    @IBOutlet weak var userActions: UIBarButtonItem!
    @IBOutlet weak var favoriteBtn: UIBarButtonItem!
    @IBOutlet weak var settingBtn: UIBarButtonItem!

    
    let spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        return  view
    }()
    var spinnerView = UIView(frame: CGRect.zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLoadingView()
        
        tableView.register(UINib(nibName: BookCell.nibName, bundle: nil), forCellReuseIdentifier: BookCell.reuseIdentifier)
        books = realm.objects(Book.self)
        if let _user = realm.objects(User.self).first {
            user = _user
            setUserActionBtn(for: _user)
            observeUser(_user)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let _user = user {
            observeUser(_user)
            if let color = (realmApp.currentUser?.customData["color"] as? AnyBSON)?.stringValue {
                configureColors(color: color)
            }
        }
    }
    
    /// Stops observing the user  in the realm when the view disappears.
    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }
    
    func configureColors(color: String) {
        navigationController?.navigationBar.tintColor = UIColor(hex: color)
        tableView.tintColor = UIColor(hex: color)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let books = books else { return 0 }
        return books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BookCell.reuseIdentifier, for: indexPath) as? BookCell else { return UITableViewCell() }
        guard let books = books else { return UITableViewCell() }
        let book = books[indexPath.row]
        // Show the books name text on the left.
        cell.configureCell(book: book, favorites: user?.favoriteBooks)
        return cell
    }
    
    func configureLoadingView() {
        spinnerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        spinner.center = spinnerView.center
        spinner.style = .large
        spinnerView.backgroundColor = UIColor.lightGray
        spinnerView.alpha = 0.5
        spinnerView.addSubview(spinner)
        spinnerView.isHidden = true
        self.tableView.addSubview(spinnerView)
    }
    
    func setLoading(_ show: Bool) {
        tableView.isScrollEnabled = !show
        show ? spinner.startAnimating() : spinner.stopAnimating()
        spinnerView.isHidden = !show
    }
    
    // MARK: - Button actions
    
    /// Change the title of the button depending on the type of authentication
    /// - Parameter user: User
    func setUserActionBtn(for user: User) {
        userActions.isEnabled = user.providerType?.provider_type == .anon
        userActions.title = user.providerType?.provider_type == .anon ? "Register" : user.userPreferences?.displayName
        favoriteBtn.isEnabled = user.providerType?.provider_type == .anon ? false : true
        settingBtn.isEnabled = user.providerType?.provider_type == .anon ? false : true
    }
    
    /// Method to launch either the login screen or to logout depending on the state of the current user
    /// - Parameter sender: Any
    @IBAction func userAction(_ sender: Any) {
        guard let user = user else { return }
        if !user.registered {
            performSegue(withIdentifier: BooksListTableViewController.loginSegue, sender: nil)
        }
    }
    
    // MARK: - Observer user
    func observeUser(_ user: User) {
        notificationToken = user.observe { changes in
            switch changes {
            case .change(let object, let properties):
                for property in properties {
                    print("Property '\(property.name)' changed")
                }
                self.tableView.reloadData()
                self.setUserActionBtn(for: object as! User)
            case .error(let error):
                print("An error occurred: \(error)")
            case .deleted:
                print("The object was deleted.")
            }
        }
    }
    
    // MARK: - Save favorite
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = user, let books = books else { return }
        let book = books[indexPath.row]
        if !user.registered {
            createAlert(title: "Register!", message: "To save \(book.volumeInfo?.title ?? "") as a favorite, you need to register first")
        } else {
            addToFavorite(user: user, book: book)
        }
        
    }
    
    fileprivate func addToFavorite(user: User, book: Book) {
        let alertController: UIAlertController
        // Check if is already added
        if !user.favoriteBooks.contains(book._id) {
            alertController = UIAlertController(title: "Add to favorites", message: "Do you want to add \(book.volumeInfo?.title ?? "") as favorite?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
                // Any writes to the Realm must occur in a write block.
                do {
                    try self.realm.write {
                        // Add the book to the wine list for the user
                        user.favoriteBooks.append(book._id)
                    }
                } catch (let error) {
                    self.reportError(error)
                }
                alertController.dismiss(animated: true)
            }))
        } else {
            alertController = UIAlertController(title: "Remove from favorites", message: "Do you want to remove \(book.volumeInfo?.title ?? "") from your favorite list?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Accept", style: .default, handler: { _ in
                // Any writes to the Realm must occur in a write block.
                do {
                    try self.realm.write {
                        if let index = user.favoriteBooks.firstIndex(of: book._id) {
                            user.favoriteBooks.remove(at: index)
                        }
                    }
                } catch (let error) {
                    self.reportError(error)
                }
                alertController.dismiss(animated: true)
            }))
        }
        present(alertController, animated: true)
    }
    
    // MARK: - Auxilar methods
    
    fileprivate func createAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            alertController.dismiss(animated: true)
        }))
        present(alertController, animated: true)
    }
    
    // MARK: - Navigation
    
    @IBAction func showFavorites(_ sender: Any) {
        guard let user = user else { return }
        performSegue(withIdentifier: BooksListTableViewController.showFavorites, sender: user)
    }
    
    @IBAction func showSettings(_ sender: Any) {
        guard let user = realmApp.currentUser else { return }
        performSegue(withIdentifier: BooksListTableViewController.showSettings, sender: user)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == BooksListTableViewController.loginSegue {
            if let vc = segue.destination as? LoginViewController, let prevUser = realmApp.currentUser {
                vc.anonUser = prevUser
                vc.delegate = self
            }
        } else if segue.identifier == BooksListTableViewController.showFavorites {
            if let vc = segue.destination as? FavoritesTableViewController, let user = sender as? User {
                vc.user = user
                vc.books = books
                vc.delegate = self
            }
        } else if segue.identifier == BooksListTableViewController.showSettings {
            if let vc = segue.destination as? SettingsViewController, let user = sender as? RLMUser {
                vc.user = user
                vc.delegate = self
            }
        }
    }
    
}

extension BooksListTableViewController: OnLoginProtocol {
    
    func didLoginSuccessful() {
        if let user = realmApp.currentUser {
            self.setLoading(true)
            
            let config = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
                subs.append(
                    QuerySubscription<Book>(name: "all-books"))
                subs.append(
                    QuerySubscription<User>(name: "user-realm"))
                
            }, rerunOnOpen: false)
            
            Realm.Configuration.defaultConfiguration = config
            Realm.asyncOpen(configuration: config) {
                result in
                self.setLoading(false)
                switch result {
                case .failure(let error):
                    print("Failed to open realm: \(error)")
                    self.reportError(error)
                case .success(let realm):
                    self.setLoading(false)
                    self.realm = realm
                    if let _user = realm.objects(User.self).first {
                        self.observeUser(_user)
                        self.setUserActionBtn(for: _user)
                        self.user = _user
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
    }
    
    func didLinkedSuccessful() {
        print("Linked successfull")
    }
}

extension BooksListTableViewController: RemoveFavoriteProtocol {
    
    /// Eliminar los favoritos desde la vista de favoritos
    /// - Parameter index: El indice del favorito a borrar
    func didRemoveFavorite(index: Int) {
        guard let user = user else { return }
        do {
            try realm.write {
                user.favoriteBooks.remove(at: index)
                self.tableView.reloadData()
            }
        } catch (let error) {
            self.reportError(error)
        }
    }
}

extension BooksListTableViewController: OnSettingChanged {
    
    func didSettingChanged(customData: [String: Any]) {
        guard let color = customData["color"] as? String else { return }
        navigationController?.navigationBar.tintColor = UIColor(hex: color)
        tableView.tintColor = UIColor(hex: color)
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}
