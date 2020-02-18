//
//  Register.swift
//  thesis
//
//  Created by yangfourone on 2020/2/18.
//  Copyright © 2020 41. All rights reserved.
//

import UIKit

class Register: UIViewController {

    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirm: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /** close keyboard when click anywhere **/
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func signUp(_ sender: Any) {
        // make an api to save register information
        if (account.text == "" || password.text == "" || confirm.text == "") {
            // set a notification showing "could not empty"
            setAlertAction(title: "錯誤", message: "請確認是否填寫所有資訊", buttonTitle: "我知道了")
        } else if (password.text != confirm.text) {
            // set a notification showing "password and confirm password should be same"
            setAlertAction(title: "錯誤", message: "密碼與確認密碼不符合", buttonTitle: "我知道了")
        } else {
            // save to database
            
            // back to login page
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}


