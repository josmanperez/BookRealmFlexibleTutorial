//
//  SettingViewController.swift
//  BookTutorialFlexible
//
//  Created by Josman Pedro Pérez Expósito on 8/7/22.
//

import UIKit
import RealmSwift
import Realm.RLMUser

enum ColorSegment: String {
    case black = "#000000FF"
    case blue = "#1AA7ECFF"
    case red = "#B22222FF"
    
    var code: Int {
        switch self {
        case .blue:
            return 0
        case .black:
            return 1
        case .red:
            return 2
        }
    }
    
    static func getColor(_ code: Int) -> ColorSegment {
        switch code {
        case 0:
            return .blue
        case 1:
            return .black
        case 2:
            return .red
        default:
            return .blue
        }
    }
}

protocol OnSettingChanged {
    func didSettingChanged(customData: [String: Any])
}


class SettingsViewController: UIViewController {
    
    var user: RLMUser?
    var delegate: OnSettingChanged?
    lazy var document: [String: Any] = [:]
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fullImageQuality: UISwitch!
    @IBOutlet weak var settingView: UIView! {
        didSet {
            settingView.layer.masksToBounds = true
            settingView.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var segmentedCrl: UISegmentedControl!
    @IBOutlet weak var saveBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _user = user else {
            dismiss(animated: true)
            return
        }
        configureView(with: _user.customData as [AnyHashable : Any])
    }
    
    func setLoading(_ loading: Bool) {
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        fullImageQuality.isEnabled = !loading
        saveBtn.isEnabled = !loading
    }
    
    func configureView(with dictionary: [AnyHashable : Any]) {
        fullImageQuality.setOn(
            (dictionary["fullImage"] as? AnyBSON)?.boolValue ?? false
            , animated: true)
        let color = ColorSegment(rawValue: (dictionary["color"] as? AnyBSON)?.stringValue ?? "#1AA7ECFF")
        segmentedCrl.selectedSegmentIndex = color?.code ?? 0
    }
    
    @IBAction func saveSettings(_ sender: Any) {
        guard let user = user else { return }
        setLoading(true)
        let color = ColorSegment.getColor(segmentedCrl.selectedSegmentIndex).rawValue
        document = ["color": color, "fullImage": fullImageQuality.isOn]
        user.functions.updateCustomData([AnyBSON(color),AnyBSON(fullImageQuality.isOn)], self.onCustomDataUpdated(result:realmError:))
    }
    
    private func onCustomDataUpdated(result: AnyBSON?, realmError: Error?) {
        DispatchQueue.main.async {
            var errorMessage: String? = nil
            
            if (realmError != nil) {
                // Error from Realm (failed function call, network error...)
                errorMessage = realmError!.localizedDescription
            } else if let resultDocument = result?.documentValue {
                // Check for user error. The addTeamMember function we defined returns an object
                // with the `error` field set if there was a user error.
                errorMessage = resultDocument["error"]??.stringValue
            } else {
                // The function call did not fail but the result was not a document.
                // This is unexpected.
                errorMessage = "Unexpected result returned from server"
            }
            // Present error message if any
            guard errorMessage == nil else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage!])
                print("Delete user failed: \(errorMessage!)")
                self.setLoading(false)
                self.reportError(error)
                return
            }
            realmApp.currentUser?.refreshCustomData { result in
                DispatchQueue.main.async {
                    self.setLoading(false)
                    switch result {
                    case .failure(let error):
                        self.reportError(error)
                    case .success(let _):
                        print("loaded custom user data")
                        self.dismiss(animated: true) { [self] in
                            delegate?.didSettingChanged(customData: document)
                        }
                    }
                }
            }
            
        }
    }
    
}
