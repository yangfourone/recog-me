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
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    var predict = ""
    var timerTask:Timer?
    
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
        
        activity.stopAnimating()
    }
    
    @IBAction func logOut(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func Start(_ sender: Any) {
        if start.currentTitle! == " Start" {
            information.text = "Setting up..."
            /** loading camera view **/
            start.setTitle(" End", for: .normal)
            imageView.isHidden = false

            CaptureManager.shared.startSession()
            CaptureManager.shared.delegate = self
            
            timerTask = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: Selector(("Recognize")), userInfo: nil, repeats: true)
            
        } else {
            /** shot down camera view **/
            start.setTitle(" Start", for: .normal)
            imageView.isHidden = true
            
            CaptureManager.shared.stopSession()

            timerTask?.invalidate()
            timerTask = nil
        }
    }
    
    @objc func Recognize() {
        uploadImage { results in
            switch results {
            case .success(let res):
                // decode
                let datadec  = res.data(using: String.Encoding.utf8)
                let decodevalue = String(data: datadec!, encoding: String.Encoding.nonLossyASCII)
                // UI
                self.information.text = decodevalue ?? "something error"
                self.activity.stopAnimating()
                break
            case .failure(let error):
                print(error.localizedDescription)
                break
            }
        }
    }
    
    func uploadImage(completion: @escaping (Result<String, Error>) -> Void) {
        // UI
        activity.startAnimating()
        
        // recognize
        let inputImage = imageView.image
        let resizedImage = resizeImage(image: inputImage!, width: 133)
        let imageBase64 = resizedImage.toBase64()
        
        let ip = getIp(method: "recognize")
        let url = URL(string: ip)
        var request = URLRequest(url: url!)
        request.httpBody = ("data=" + imageBase64!).data(using: .utf8)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil && data != nil else {
                print("error=\(String(describing: error))")
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }

            let responseString = String(data: data!, encoding: .utf8)
            
            DispatchQueue.main.async {
                completion(.success(responseString!))
            }
        }.resume()
    }
    
    // save image to album
    func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    // resize image
    func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
            let size = CGSize(width: width, height:
                image.size.height * width / image.size.width)
            let renderer = UIGraphicsImageRenderer(size: size)
            let newImage = renderer.image { (context) in
                image.draw(in: renderer.format.bounds)
            }
            return newImage
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
