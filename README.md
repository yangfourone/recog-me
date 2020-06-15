If recognition source is from a video, you need to make some changes.

 - COMMENT
   
   1. `CaptureManager.shared.startSession()`   [In "Start" @IBAction]
   2. `CaptureManager.shared.delegate = self`   [In "Start" @IBAction]
   3. `CaptureManager.shared.stopSession()`   [In "End" @IBAction]

 - DECOMMENT

   1. `Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.playFromVideo), userInfo: nil, repeats: false)`   [In "Start" @IBAction]
   2. `recognizeFromVideo(videoName: testVideoName, fileExtension: "MOV", interval: 2)`   [In "Recognize" @objc func]
   3. `let testVideoName = "YOUR_VIDEO_NAME"`   [In parameter definition, file extension is .MOV]
