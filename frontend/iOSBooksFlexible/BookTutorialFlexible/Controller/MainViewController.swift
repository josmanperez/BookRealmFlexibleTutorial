//
//  MainViewController.swift
//  BookTutorialFlexible
//
//  Created by Josman Pedro Pérez Expósito on 9/6/22.
//

import UIKit
import RealmSwift
import Realm.RLMUser

class MainViewController: UIViewController {
    
    static let showApp = "showApp"
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleLoggein()
    }
    
    fileprivate func handleLoggein() {
        // If a user is already looged in, return true
        if let user = realmApp.currentUser {
            setDefaultConfiguration(forUser: user)
            refreshCustomData(user: user) {
                DispatchQueue.main.async {
                    self.setLoading(false)
                    self.performSegue(withIdentifier: MainViewController.showApp, sender: nil)
                }
            }
        } else {
            anonymousSignIn()
        }
    }
    
    func setLoading(_ loading: Bool) {
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    func refreshCustomData(user: RLMUser, completion: @escaping (()->())) {
        user.refreshCustomData { (_) in
            completion()
        }
    }
    
    /// Logs in with an existing user.
    func anonymousSignIn() {
        setLoading(true)
        realmApp.login(credentials: Credentials.anonymous) { result in
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case let .failure(error):
                    print("Failed to log in: \(error)")
                    self.reportError(error)
                case let .success(user):
                    print("The user has been authenticated using anonymous auth")
                    self.onSignInComplete(user)
                }
            }
        }
    }
    
    /// Called when sign in completes. Opens the realm asynchronously and navigates to the BooksView screen.
    func onSignInComplete(_ user: RLMUser) {
        setLoading(true)
        openRealm(for: user)
    }
    
    fileprivate func openRealm(for user: RLMUser) {
        setDefaultConfiguration(forUser: user)
        Realm.asyncOpen() {
            result in
            self.setLoading(false)
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error)")
                self.reportError(error)
            case .success( _):
                self.setLoading(false)
                self.performSegue(withIdentifier: MainViewController.showApp, sender: nil)
            }
        }
    }
    
    
    /// Default configuration will open all `book` which `show` property is `true` as a `subscription`
    /// - Parameter user: The authenticated user
    func setDefaultConfiguration(forUser user: RLMUser) {
        let config = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
            subs.append(
                QuerySubscription<Book>(name: "all-books"))
            subs.append(
                QuerySubscription<User>(name: "user-realm"))
            
        }, rerunOnOpen: true)
        Realm.Configuration.defaultConfiguration = config
    }
    
}

extension UIViewController {
    /// Presents the user with an error alert.
    func reportError(_ error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            alertController.dismiss(animated: true)
        }))
        present(alertController, animated: true)
    }
}
