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
    
    // For Analysis
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var reset: UIButton!
    var error:Int = 0
    var total:Int = 0
    var rate:Float = 0.0
    
    // For upload image to server
    var timerTask:Timer?
    
    // For relative altitude
    let altimeter = CMAltimeter()
    
    // For tag update
    var directionTag:UIImageView?
    var resetCounter = 4
    var updateBool:Bool = true
    var lastBuilding:String?
    var lastFloor:String?
    var lastPosition:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /** view styling **/
        end.isHidden = true
        record.isHidden = true
        
        cameraViewMask.layer.cornerRadius = 8
        cameraViewMask.layer.borderColor = UIColor.white.cgColor
        cameraViewMask.layer.borderWidth = 3
        cameraViewMask.backgroundColor = UIColor(white: 0, alpha: 1)
        
        indoorMap.layer.cornerRadius = 8
        cameraView.layer.cornerRadius = 8
        
        indoorMapMask.layer.cornerRadius = 8
        indoorMapMask.layer.borderColor = UIColor.white.cgColor
        indoorMapMask.layer.borderWidth = 3
        indoorMapMask.backgroundColor = UIColor(white: 0, alpha: 1)
        
        // startRelativeAltitudeUpdates()
        activity.stopAnimating()
    }
    
    // MARK: GET DATA
    var second = 0
    
    func recognizeFromVideo(videoName: String, fileExtension: String, interval: Int) {
        let audioFilePath = Bundle.main.path(forResource: videoName, ofType: fileExtension)
        let image = self.imageFromVideo(url: URL(fileURLWithPath: audioFilePath!), at: TimeInterval(second))
        self.cameraView.image = image
        second += interval
    }

    func imageFromVideo(url: URL, at time: TimeInterval) -> UIImage? {
        let asset = AVURLAsset(url: url)

        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

        let cmTime = CMTime(seconds: time, preferredTimescale: 60)
        let thumbnailImageRef: CGImage
        do {
            thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }

        return UIImage(cgImage: thumbnailImageRef)
    }
    
    // MARK: Start Button
    @IBAction func Start(_ sender: Any) {
        /** UI update **/
        cameraViewMask.backgroundColor = UIColor(white: 0, alpha: 0)
        indoorMapMask.backgroundColor = UIColor(white: 0, alpha: 0)
        end.isHidden = false
        start.isHidden = true
        record.isHidden = false
        reset.isHidden = true
        directionTag?.isHidden = false
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
        record.isHidden = true
        reset.isHidden = false
        directionTag?.isHidden = true
        information.text = ""
        /** shot down camera view **/
        cameraView.isHidden = true
        indoorMap.isHidden = true
        
        CaptureManager.shared.stopSession()

        timerTask?.invalidate()
        timerTask = nil
    }
    
    // MARK: Record Button
    @IBAction func Record(_ sender: Any) {
        error += 1
        updateErrorRate()
    }
    
    // MARK: Reset Button
    @IBAction func Reset(_ sender: Any) {
        let alertController = UIAlertController(title: "注意！", message: "確定刪除底下的統計資料？", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "確認刪除", style: .default) { (_) in
            self.updateBool = true
            self.resetCounter = 4
            self.lastBuilding = nil
            self.lastFloor = nil
            self.lastPosition = nil
            self.error = 0
            self.total = 0
            self.rate = 0.0
            self.errorLabel.text = "Error: 0"
            self.totalLabel.text = "Total: 0"
            self.rateLabel.text = "Rate: 0.00%"
        }
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Upload and Get Response
    @objc func Recognize() {
        
        // MARK: using for collecting comparison data
        // recognizeFromVideo(videoName: "8F", fileExtension: "MOV", interval: 2)
        
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
                        self.resetCounter += 1
                        self.total += 1
                        self.recognizeChecking(jsonArray: jsonArray)
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
    
    // MARK: 相對高度偵測
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
            // 相對高度
            print("\(altitudeData!.relativeAltitude) m\n")
        })
    }
    
    // MARK: Checking
    func recognizeChecking(jsonArray: [Dictionary<String,Any>]) {
        let index = 0
        
        getTagNeighbor(building: jsonArray[index]["building"]! as! String, floor: jsonArray[index]["floor"]! as! String, position: jsonArray[index]["position"]! as! String)
        
        // if neighbor, that will update information
        if updateBool {
            // update indoor map layout
            updateIndoorMap(building: jsonArray[index]["building"]! as! String, floor: jsonArray[index]["floor"]! as! String, position: jsonArray[index]["position"]! as! String, degree: jsonArray[index]["degree"]! as! String, chineseLabel: jsonArray[index]["chinese"]! as! String)
        } else {
            
            // MARK: Information TextField
            information.text = "Last: \(lastBuilding ?? "nil") \(lastFloor ?? "nil") \(lastPosition ?? "nil"), Current: \(jsonArray[index]["building"]! as! String) \(jsonArray[index]["floor"]! as! String) \(jsonArray[index]["position"]! as! String), Counter: \(resetCounter)"
        }
        updateErrorRate()
    }
    
    // MARK: Update Error Rate
    func updateErrorRate() {
        errorLabel.text = "Error: \(error)"
        totalLabel.text = "Total: \(total)"
        rate = Float(error)/Float(total)*100
        rateLabel.text = "Rate: \(String(format: "%.2f", rate))%"
    }
    
    // MARK: Update Indoor Map
    func updateIndoorMap(building: String, floor: String, position: String, degree: String, chineseLabel: String) {
        indoorMap.image = UIImage(named: "\(floor).png")
        setResponseParameter(building: building, floor: floor, position: position, degree: degree, chineseLabel: chineseLabel)
    }
    
    // MARK: Show Parameters to Label
    func setResponseParameter(building: String, floor: String, position: String, degree: String, chineseLabel: String) {
        getTagPosition(building: building, floor: floor, position: position, degree: degree)
        
        // MARK: Information TextField
        information.text = "Last: \(lastBuilding ?? "nil") \(lastFloor ?? "nil") \(lastPosition ?? "nil"), Current: \(building) \(floor) \(position), Counter: \(resetCounter)"

        // update last position information
        lastBuilding = building
        lastFloor = floor
        lastPosition = position
    }
    
    // MARK: Get Tag x-axis and y-axis
    func getTagPosition (building: String, floor: String, position: String, degree: String) {
        let tagCoordinate = getTagCoordinate()
        for index in 0..<tagCoordinate.count {
            if building == tagCoordinate[index]["building"] as! String && floor == tagCoordinate[index]["floor"] as! String && position == tagCoordinate[index]["position"] as! String {
                showTag(x: tagCoordinate[index]["x-axis"] as! Int, y: tagCoordinate[index]["y-axis"] as! Int, degree: degree)
            }
        }
    }
    
    // MARK: Show The Tag
    func showTag(x:Int, y:Int, degree:String) {
        
        let imageName = "\(degree).png"
        let image = UIImage(named: imageName)
        
        if directionTag != nil {
            // Fix Position
            directionTag!.removeFromSuperview()
            directionTag = UIImageView(image: image!)
            directionTag!.frame = CGRect(x: x, y: y, width: 15, height: 15)
            view.addSubview(directionTag!)
        } else {
            // Add
            directionTag = UIImageView(image: image!)
            directionTag!.frame = CGRect(x: x, y: y, width: 15, height: 15)
            view.addSubview(directionTag!)
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

extension Recognize {

    // MARK: Tag Information Definition
    
    func getTagCoordinate() -> [Dictionary<String,Any>] {
        let tag:[Dictionary<String,Any>] = [
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "A",
                "x-axis" : 911,
                "y-axis" : 683
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "B",
                "x-axis" : 823,
                "y-axis" : 683
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "C",
                "x-axis" : 766,
                "y-axis" : 683
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "D",
                "x-axis" : 705,
                "y-axis" : 744
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "E",
                "x-axis" : 705,
                "y-axis" : 683
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "F",
                "x-axis" : 705,
                "y-axis" : 663
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "G",
                "x-axis" : 632,
                "y-axis" : 663
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "H",
                "x-axis" : 564,
                "y-axis" : 663
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "I",
                "x-axis" : 468,
                "y-axis" : 663
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "J",
                "x-axis" : 386,
                "y-axis" : 663
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "K",
                "x-axis" : 386,
                "y-axis" : 743
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "A",
                "x-axis" : 781,
                "y-axis" : 683
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "B",
                "x-axis" : 705,
                "y-axis" : 744
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "C",
                "x-axis" : 705,
                "y-axis" : 677
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "D",
                "x-axis" : 633,
                "y-axis" : 677
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "E",
                "x-axis" : 535,
                "y-axis" : 677
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "F",
                "x-axis" : 469,
                "y-axis" : 677
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "G",
                "x-axis" : 373,
                "y-axis" : 677
            ]
        ]
        
        return tag
    }

    
    // MARK: Tag Neighbor Definition
    
    func getTagNeighbor(building: String, floor: String, position: String) {
        
        let neighborTable = [
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "A",
                "neighbor" : "A,B,C"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "B",
                "neighbor" : "A,B,C,E"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "C",
                "neighbor" : "A,B,C,D,E,F"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "D",
                "neighbor" : "C,D,E,F"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "E",
                "neighbor" : "B,C,D,E,F,G"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "F",
                "neighbor" : "C,D,E,F,G,H"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "G",
                "neighbor" : "E,F,G,H,I"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "H",
                "neighbor" : "F,G,H,I,J"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "I",
                "neighbor" : "G,H,I,J,K"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "J",
                "neighbor" : "H,I,J,K"
            ],
            [
                "building" : "EE",
                "floor" : "7F",
                "position" : "K",
                "neighbor" : "I,J,K"
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "A",
                "neighbor" : "A,B,C"
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "B",
                "neighbor" : "A,B,C,D"
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "C",
                "neighbor" : "A,B,C,D"
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "D",
                "neighbor" : "A,B,C,D,E"
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "E",
                "neighbor" : "C,D,E,F,G"
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "F",
                "neighbor" : "D,E,F,G"
            ],
            [
                "building" : "EE",
                "floor" : "8F",
                "position" : "G",
                "neighbor" : "E,F,G"
            ]
        ]
        
        // except first time in this function
        if lastBuilding != nil && lastFloor != nil && lastPosition != nil {
            for index in 0..<neighborTable.count {
                // get last position's neighbor
                if lastBuilding == neighborTable[index]["building"]! && lastFloor == neighborTable[index]["floor"]! && lastPosition == neighborTable[index]["position"]! {
                    // split every neighbor into array
                    let tagNeighbor = neighborTable[index]["neighbor"]!
                    let neighborArray = tagNeighbor.split(separator: ",")
                    
                    for index in 0..<neighborArray.count {
                        
                        // if the neighbor exists, that means it is valid
                        // else we need to have a counter to record how many times we can not recognize position. we should reset if much more 4 times
                        if resetCounter < 4 {
                            if position == neighborArray[index] && floor == lastFloor {
                                updateBool = true
                                resetCounter = 0
                                break
                            } else {
                                updateBool = false
                                if index == neighborArray.count {
                                    break
                                }
                            }
                        } else {
                            // reset current position
                            print("\n------------------ RESET POSITION ------------------\n")
                            updateBool = true
                            resetCounter = 0
                            break
                        }
                    }
                    break
                }
            }
        } else {
            // first time in this function
            updateBool = true
        }
    }
}
