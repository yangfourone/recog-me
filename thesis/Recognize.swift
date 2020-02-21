//
//  Recognize.swift
//  thesis
//
//  Created by yangfourone on 2020/2/18.
//  Copyright © 2020 41. All rights reserved.
//

import UIKit
import AVFoundation

class Recognize: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var left: UIView!
    @IBOutlet weak var right: UIView!
    @IBOutlet weak var information: UILabel!
    @IBOutlet weak var start: UIButton!

    var flag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /** view styling **/
        left.layer.cornerRadius = 8
        left.layer.borderColor = UIColor.white.cgColor
        left.layer.borderWidth = 3
        left.backgroundColor = UIColor(white: 1, alpha: 0)
        
        right.layer.cornerRadius = 8
        right.layer.borderColor = UIColor.white.cgColor
        right.layer.borderWidth = 3
        right.backgroundColor = UIColor(white: 1, alpha: 0)
    }
    
    @IBAction func logOut(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func Start(_ sender: Any) {
        if start.currentTitle! == " Start" {
            flag = true
            /** loading camera view **/
            start.setTitle(" End", for: .normal)
            imageView.isHidden = false

            CaptureManager.shared.statSession()
            CaptureManager.shared.delegate = self
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.Recognize()
            })
        } else {
            flag = false
            /** shot down camera view **/
            start.setTitle(" Start", for: .normal)
            imageView.isHidden = true
            
            CaptureManager.shared.stopSession()
        }
    }
    
    func Recognize() {
        let inputImage = imageView.image
        print(inputImage!.size)
        saveImage(image: inputImage!)
        let imageBase64 = inputImage!.toBase64()
        let ip = getIp(method: "upload-image")
        let url = URL(string: ip)
        var request = URLRequest(url: url!)
        request.httpBody = ("data=" + imageBase64!).data(using: .utf8)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil && data != nil else {
                print("error=\(String(describing: error))")
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }

            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
    
    func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

extension UIInterfaceOrientation {

    public var videoOrientation: AVCaptureVideoOrientation {
        switch self {
            case .portrait:
                return AVCaptureVideoOrientation.portrait
            case .landscapeRight:
                return AVCaptureVideoOrientation.landscapeRight
            case .landscapeLeft:
                return AVCaptureVideoOrientation.landscapeLeft
            case .portraitUpsideDown:
                return AVCaptureVideoOrientation.portraitUpsideDown
            default:
                return AVCaptureVideoOrientation.portrait
        }
    }
}

extension UIImage {
    func toBase64() -> String? {
        guard let imageData = self.pngData() else { return nil }
        return imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
    }
}

extension Recognize: CaptureManagerDelegate {
    func processCapturedImage(image: UIImage) {
        self.imageView.image = image
    }
}
