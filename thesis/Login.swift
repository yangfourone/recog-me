//
//  Login.swift
//  thesis
//
//  Created by yangfourone on 2020/2/18.
//  Copyright © 2020 41. All rights reserved.
//

import UIKit

class Login: UIViewController {
    
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var logIn: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /** button styling **/
        logIn.layer.cornerRadius = 8
        
        /** close keyboard when click anywhere **/
        self.hideKeyboardWhenTappedAround()
    }

    @IBAction func register(_ sender: Any) {
        let RegisterViewController = self.storyboard?.instantiateViewController(withIdentifier: "Register") as! Register
        present(RegisterViewController, animated: true, completion: nil)
    }
    @IBAction func logIn(_ sender: Any) {
        let RecognizeViewController = self.storyboard?.instantiateViewController(withIdentifier: "Recognize") as! Recognize
        present(RecognizeViewController, animated: true, completion: nil)
    }
}


extension UIViewController {
    /** Close Keyboard **/
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /** Alert Action **/
    func setAlertAction(title: String, message: String, buttonTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: buttonTitle, style: .default)
        alertController.addAction(okAction)
        show(alertController, sender: self)
    }
}
