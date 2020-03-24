//
//  Recognize.swift
//  thesis
//
//  Created by yangfourone on 2020/2/18.
//  Copyright © 2020 41. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

class Recognize: UIViewController {
    
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var indoorMap: UIImageView!
    @IBOutlet weak var cameraViewMask: UIView!
    @IBOutlet weak var indoorMapMask: UIView!
    @IBOutlet weak var information: UILabel!
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var end: UIButton!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    var timerTask:Timer?
    let altimeter = CMAltimeter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /** view styling **/
        end.isHidden = true
        
        cameraViewMask.layer.cornerRadius = 8
        cameraViewMask.layer.borderColor = UIColor.white.cgColor
        cameraViewMask.layer.borderWidth = 3
        cameraViewMask.backgroundColor = UIColor(white: 0, alpha: 1)
        
        indoorMapMask.layer.cornerRadius = 8
        indoorMapMask.layer.borderColor = UIColor.white.cgColor
        indoorMapMask.layer.borderWidth = 3
        indoorMapMask.backgroundColor = UIColor(white: 0, alpha: 1)
        
//        startRelativeAltitudeUpdates()
        activity.stopAnimating()
    }
    
    @IBAction func logOut(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func Start(_ sender: Any) {
        /** UI update **/
        cameraViewMask.backgroundColor = UIColor(white: 0, alpha: 0)
        indoorMapMask.backgroundColor = UIColor(white: 0, alpha: 0)
        end.isHidden = false
        start.isHidden = true
        information.text = NSLocalizedString("Recognize_Information_Setting", comment: "")
        /** loading camera view **/
        cameraView.isHidden = false
        indoorMap.isHidden = false

        CaptureManager.shared.startSession()
        CaptureManager.shared.delegate = self
        
        timerTask = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: Selector(("Recognize")), userInfo: nil, repeats: true)
    }
    
    @IBAction func End(_ sender: Any) {
        /** UI update **/
        cameraViewMask.backgroundColor = UIColor(white: 0, alpha: 1)
        indoorMapMask.backgroundColor = UIColor(white: 0, alpha: 1)
        cameraViewMask.isHidden = false
        indoorMapMask.isHidden = false
        end.isHidden = true
        start.isHidden = false
        information.text = ""
        /** shot down camera view **/
        cameraView.isHidden = true
        indoorMap.isHidden = true
        
        CaptureManager.shared.stopSession()

        timerTask?.invalidate()
        timerTask = nil
    }
    
    @objc func Recognize() {
        uploadImage { results in
            switch results {
            case .success(let res):
                /**  decode **/
                let datadec = res.data(using: String.Encoding.utf8)
                let decodevalue = String(data: datadec!, encoding: String.Encoding.nonLossyASCII)
                let data = decodevalue!.data(using: .utf8)!
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>]
                    {
                        self.floorRecognize(jsonArray: jsonArray)
                    } else {
                        print("bad json")
                    }
                } catch let error as NSError {
                    print(error)
                }
                
                /** UI **/
                self.activity.stopAnimating()
                break
            case .failure(let error):
                print(error.localizedDescription)
                break
            }
        }
    }
    
    func startRelativeAltitudeUpdates() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            print("\n當前設備不支援獲取高度\n")
            return
        }

        let queue = OperationQueue.current
        self.altimeter.startRelativeAltitudeUpdates(to: queue!, withHandler: {
            (altitudeData, error) in
            guard error == nil else {
                print(error!)
                return
            }
            // 千帕
            print("\n\(altitudeData!.pressure) kPa")
            // 百帕
            print("\(Float(truncating: altitudeData!.pressure)*10.0) hPa")
            // 相對高度
            print("\(altitudeData!.relativeAltitude) m")
        })
    }
    
    func uploadImage(completion: @escaping (Result<String, Error>) -> Void) {
        /** UI **/
        activity.startAnimating()
        
        /** recognize **/
        let inputImage = cameraView.image
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
    
    /** resize image **/
    func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
            let size = CGSize(width: width, height:
                image.size.height * width / image.size.width)
            let renderer = UIGraphicsImageRenderer(size: size)
            let newImage = renderer.image { (context) in
                image.draw(in: renderer.format.bounds)
            }
            return newImage
    }
    
    /** floor recognize **/
    func floorRecognize(jsonArray: [Dictionary<String,Any>]) {
        setResponseParameter(building: jsonArray[0]["building"]! as! String, floor: jsonArray[0]["floor"]! as! String, position: jsonArray[0]["position"]! as! String, degree: jsonArray[0]["degree"]! as! String, chineseLabel: jsonArray[0]["chinese"]! as! String)
    }
    
    /** parameters **/
    func setResponseParameter(building: String, floor: String, position: String, degree: String, chineseLabel: String) {
        information.text = "\(building) \(floor) \(position) \(degree) \(chineseLabel)"
    }
    
    /** save image to album **/
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
        self.cameraView.image = image
    }
}
