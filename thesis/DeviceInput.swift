//
//  DeviceInput.swift
//  thesis
//
//  Created by yangfourone on 2020/2/18.
//  Copyright © 2020 41. All rights reserved.
//

import AVFoundation

class DeviceInput: NSObject {
    // 前置廣角鏡頭
    var frontWildAngleCamera: AVCaptureDeviceInput?
    // 後置廣角鏡頭
    var backWildAngleCamera: AVCaptureDeviceInput?
    // 後置望遠鏡頭
    var backTelephotoCamera: AVCaptureDeviceInput?
    // 後置廣雙鏡頭
    var backDualCamera: AVCaptureDeviceInput?
    
    func getAllCameras() {
        let cameraDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInDualCamera],
            mediaType: .video,
            position: .unspecified).devices
        
        for camera in cameraDevices {
            let inputDevice = try! AVCaptureDeviceInput(device: camera)
            
            if camera.deviceType == .builtInWideAngleCamera, camera.position == .front {
                frontWildAngleCamera = inputDevice
            }
            
            if camera.deviceType == .builtInWideAngleCamera, camera.position == .back {
                backWildAngleCamera = inputDevice
            }
            
            if camera.deviceType == .builtInTelephotoCamera {
                backTelephotoCamera = inputDevice
            }
            
            if camera.deviceType == .builtInDualCamera {
                backDualCamera = inputDevice
            }
        }
    }
    
    override init() {
        super.init()
        getAllCameras()
    }
}
