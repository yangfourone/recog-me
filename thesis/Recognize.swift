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
import CoreLocation

class Recognize: UIViewController, CLLocationManagerDelegate {
    
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
    var hPa:Float = 0.0
    var counterForBarometer = 0
    var valueForBarometer:Float = 0.0
    
    var LM = CLLocationManager()
    
    var directionTag:UIImageView?
    
    // MARK: Tag Information Definition
    let tagInformation:[Dictionary<String,Any>] = [
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "A",
            "x-axis" : 805,
            "y-axis" : 696
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "B",
            "x-axis" : 730,
            "y-axis" : 696
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "C",
            "x-axis" : 679,
            "y-axis" : 696
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "D",
            "x-axis" : 626,
            "y-axis" : 749
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "E",
            "x-axis" : 626,
            "y-axis" : 696
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "F",
            "x-axis" : 626,
            "y-axis" : 677
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "G",
            "x-axis" : 559,
            "y-axis" : 677
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "H",
            "x-axis" : 507,
            "y-axis" : 677
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "I",
            "x-axis" : 425,
            "y-axis" : 677
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "J",
            "x-axis" : 340,
            "y-axis" : 677
        ],
        [
            "building" : "EE",
            "floor" : "7F",
            "position" : "K",
            "x-axis" : 340,
            "y-axis" : 749
        ],
        [
            "building" : "EE",
            "floor" : "8F",
            "position" : "A",
            "x-axis" : 681,
            "y-axis" : 696
        ],
        [
            "building" : "EE",
            "floor" : "8F",
            "position" : "B",
            "x-axis" : 625,
            "y-axis" : 750
        ],
        [
            "building" : "EE",
            "floor" : "8F",
            "position" : "C",
            "x-axis" : 625,
            "y-axis" : 689
        ],
        [
            "building" : "EE",
            "floor" : "8F",
            "position" : "D",
            "x-axis" : 560,
            "y-axis" : 689
        ],
        [
            "building" : "EE",
            "floor" : "8F",
            "position" : "E",
            "x-axis" : 468,
            "y-axis" : 689
        ],
        [
            "building" : "EE",
            "floor" : "8F",
            "position" : "F",
            "x-axis" : 409,
            "y-axis" : 689
        ],
        [
            "building" : "EE",
            "floor" : "8F",
            "position" : "G",
            "x-axis" : 328,
            "y-axis" : 689
        ]
    ]
    
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
        
        startRelativeAltitudeUpdates()
        activity.stopAnimating()
        
        /** location manager **/
        LM.requestWhenInUseAuthorization()
        LM.requestAlwaysAuthorization()
        LM.delegate = self
        LM.startUpdatingLocation()
    }
    
    // MARK: Log Out Button
    @IBAction func logOut(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Start Button
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
        
        timerTask = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.Recognize), userInfo: nil, repeats: true)
    }
    
    // MARK: End Button
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
    
    // MARK: Upload and Get Response
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
                        self.floorRecognize(jsonArray: jsonArray, pressure: self.hPa)
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
    
    // MARK: 氣壓偵測與相對高度偵測
    func startRelativeAltitudeUpdates() {
//        guard CMAltimeter.isRelativeAltitudeAvailable() else {
//            print("\n當前設備不支援獲取高度\n")
//            return
//        }
//
//        let queue = OperationQueue.current
//        self.altimeter.startRelativeAltitudeUpdates(to: queue!, withHandler: {
//            (altitudeData, error) in
//            guard error == nil else {
//                print(error!)
//                return
//            }
//            // 百帕
//            self.hPa = Float(truncating: altitudeData!.pressure)*10.0
//
//            self.counterForBarometer += 1
//            self.valueForBarometer += self.hPa
//            let averageBarometerValue = self.valueForBarometer / Float(self.counterForBarometer)
//            self.information.text = "Times: \(self.counterForBarometer), Average: \(averageBarometerValue)"
//
//            // 相對高度
//            print("\(altitudeData!.relativeAltitude) m\n")
//        })
    }
    
    // MARK: Floor Recognize ??
    func floorRecognize(jsonArray: [Dictionary<String,Any>], pressure: Float) {
        let index = 0
        indoorMap.image = UIImage(named: "\(jsonArray[index]["floor"]! as! String).png")
        setResponseParameter(building: jsonArray[index]["building"]! as! String, floor: jsonArray[index]["floor"]! as! String, position: jsonArray[index]["position"]! as! String, degree: jsonArray[index]["degree"]! as! String, chineseLabel: jsonArray[index]["chinese"]! as! String)
    }
    
    // MARK: Show Parameters to Label
    func setResponseParameter(building: String, floor: String, position: String, degree: String, chineseLabel: String) {
        getTagPosition(building: building, floor: floor, position: position, degree: degree)
        information.text = "\(building) \(floor) \(position) \(degree) \(chineseLabel)"
    }
    
    // MARK: Get Tag x-axis and y-axis
    func getTagPosition (building: String, floor: String, position: String, degree: String) {
        for index in 0..<tagInformation.count {
            if building == tagInformation[index]["building"] as! String && floor == tagInformation[index]["floor"] as! String && position == tagInformation[index]["position"] as! String {
                showTag(x: tagInformation[index]["x-axis"] as! Int, y: tagInformation[index]["y-axis"] as! Int, degree: degree)
            }
        }
    }
    
    // MARK: Show The Tag
    func showTag(x:Int, y:Int, degree:String) {
        if directionTag != nil {
            directionTag?.removeFromSuperview()
        }
        let imageName = "\(degree).png"
        let image = UIImage(named: imageName)
        directionTag = UIImageView(image: image!)
        directionTag!.frame = CGRect(x: x, y: y, width: 15, height: 15)
        view.addSubview(directionTag!)
    }
    
    // MARK: GPS Location Information (altitude)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
//            print("高度: \(location.altitude)\n")
        }
    }
    
    // MARK: Upload Image
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
    
    // MARK: Resize Image
    func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
            let size = CGSize(width: width, height:
                image.size.height * width / image.size.width)
            let renderer = UIGraphicsImageRenderer(size: size)
            let newImage = renderer.image { (context) in
                image.draw(in: renderer.format.bounds)
            }
            return newImage
    }
    
    // MARK: Save Image To Album
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
