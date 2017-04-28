//
//  ViewController.swift
//  FlatironChat
//
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    @IBOutlet weak var screenNameField: UITextField!

    let firebaseManager = FirebaseManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()

    }


    @IBAction func joinBtnPressed(_ sender: Any) {
        if let screenName = screenNameField.text {
            firebaseManager.anonymousSignIn() { user in
                if user != nil {
                    UserDefaults.standard.set(screenName, forKey: "screenName")
                    self.performSegue(withIdentifier: "openChannel", sender: self)
                } else {
                    let alertVC = UIAlertController(title: "you wrong", message: "", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertVC.addAction(okAction)
                    self.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
}

