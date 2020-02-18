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
    
    @IBOutlet weak var vision: UIView!
    @IBOutlet weak var left: UIView!
    @IBOutlet weak var right: UIView!
    @IBOutlet weak var information: UILabel!
    @IBOutlet weak var start: UIButton!
    
    let session = AVCaptureSession()
    let deviceInput = DeviceInput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    func settingPreviewLayer() {
        previewLayer.frame = vision.bounds
        
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        
        vision.layer.addSublayer(previewLayer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /** view styling **/
        vision.layer.borderColor = UIColor.black.cgColor
        
        left.layer.cornerRadius = 8
        left.layer.borderColor = UIColor.white.cgColor
        left.layer.borderWidth = 3
        left.backgroundColor = UIColor(white: 1, alpha: 0)
        
        right.layer.cornerRadius = 8
        right.layer.borderColor = UIColor.white.cgColor
        right.layer.borderWidth = 3
        right.backgroundColor = UIColor(white: 1, alpha: 0)
        
        settingPreviewLayer()
        session.addInput(deviceInput.backWildAngleCamera!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayerConnection =  self.previewLayer.connection, previewLayerConnection.isVideoOrientationSupported {
            previewLayerConnection.videoOrientation = UIApplication.shared.statusBarOrientation.videoOrientation
        }
    }
    
    @IBAction func logOut(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func Start(_ sender: Any) {
        if start.currentTitle! == " Start" {
            /** loading camera view **/
            start.setTitle(" End", for: .normal)
            vision.isHidden = false
            session.startRunning()
        } else {
            /** shot down camera view **/
            start.setTitle(" Start", for: .normal)
            vision.isHidden = true
            session.stopRunning()
        }
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
