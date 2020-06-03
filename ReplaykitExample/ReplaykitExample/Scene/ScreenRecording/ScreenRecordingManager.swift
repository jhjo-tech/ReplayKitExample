//
//  ScreenRecordingManager.swift
//  ReplaykitExmaple
//
//  Created by Bruce on 2020/06/03.
//  Copyright © 2020 jhjo. All rights reserved.
//

import ReplayKit
import Photos

extension ScreenRecordingManager {
    enum State: String {
        case start
        case recroding
        case stop
        case saveVideo
        case completed
    }
}

class ScreenRecordingManager {
    static let shared = ScreenRecordingManager()
    
    private var docuementPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let screenRecorder = RPScreenRecorder.shared()
    
    private var videoSavedPath: URL?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioMicInput: AVAssetWriterInput?
    private var audioAppInput: AVAssetWriterInput?
    private var currentState: State = .start {
        didSet {
            currentStateHandler?(self.currentState)
        }
    }
    
    var startCompletedHandler: ((Error?) -> Void)?
    var currentStateHandler: ((State) -> Void)?
}

// MARK: - setup
extension ScreenRecordingManager {
    
    func setupRecorder() {
        print(#function)
        if currentState == .recroding {
            self.stopCapture()
        }
        
        self.currentState = .start
        
        screenRecorder.isMicrophoneEnabled = true
        setupVideoAssetWriter()
    }
    
    private func setupVideoAssetWriter() {
        print(#function)
        videoSavedPath = createPath(to: "mp4")
        
        guard let path = videoSavedPath else { print("Error : Empty Paath"); return }
        
        print("video Saved path : \(path)")
        
        do {
            assetWriter = try AVAssetWriter(url: path, fileType: .mp4)
            createVideoInput()
            createAudioMicInput()
            createAudioAppInput()
        } catch {
            print("Failed starting screen capture: \(error.localizedDescription)")
        }
    }

    private func createVideoInput() {
        let videoCompressionProperties: Dictionary<String, Any> = [
            AVVideoAverageBitRateKey : 2500000, // youtubu 720p Quality (https://ko.wikipedia.org/wiki/비트레이트)
            AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
            AVVideoExpectedSourceFrameRateKey: 30
        ]
        
        let videoSettings: [String : Any] = [
            AVVideoCodecKey  : AVVideoCodecType.h264,
            AVVideoWidthKey  : CGFloat(1280),
            AVVideoHeightKey : CGFloat(720),
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
            AVVideoCompressionPropertiesKey : videoCompressionProperties
        ]
        
        self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        self.videoInput?.expectsMediaDataInRealTime = true
        guard let videoInput = self.videoInput else { print("Video Input Empty"); return }
        self.assetWriter?.add(videoInput)
    }
    
    private func createAudioMicInput() {
        var audioMicSettings: [String : Any] = [:]
        audioMicSettings[AVFormatIDKey] = kAudioFormatMPEG4AAC_HE
        audioMicSettings[AVSampleRateKey] = 44100
        audioMicSettings[AVEncoderBitRateKey] = 64000
        audioMicSettings[AVNumberOfChannelsKey] = 2
        
        self.audioMicInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioMicSettings)
        self.audioMicInput?.expectsMediaDataInRealTime = true
        
        guard let audioInput = self.audioMicInput else { print("AudioMic Input Empty"); return }
        self.assetWriter?.add(audioInput)
    }
    
    private func createAudioAppInput() {
        var audioAppSettings: [String : Any] = [:]
        audioAppSettings[AVFormatIDKey] = kAudioFormatMPEG4AAC_HE
        audioAppSettings[AVSampleRateKey] = 44100
        audioAppSettings[AVEncoderBitRateKey] = 64000
        audioAppSettings[AVNumberOfChannelsKey] = 2
        
        self.audioAppInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioAppSettings)
        self.audioAppInput?.expectsMediaDataInRealTime = true
        
        guard let audioInput = self.audioAppInput else { print("AudioApp Input Empty"); return }
        self.assetWriter?.add(audioInput)
    }
}


extension ScreenRecordingManager {
    func start() {
        print(#function)
        screenRecorder.startCapture(handler: { [weak self] (cmSampleBuffer, sampleType, error) in
            guard let self = self else { return }
            guard error == nil else { return }
            
            self.startSession(cmSampleBuffer, type: sampleType)
  
            switch sampleType {
            case .video:
                guard self.videoInput?.isReadyForMoreMediaData ?? false else { return }
                self.videoInput?.append(cmSampleBuffer)
            case .audioMic:
                guard self.audioMicInput?.isReadyForMoreMediaData ?? false else { return }
                self.audioMicInput?.append(cmSampleBuffer)
            case .audioApp:
                guard self.audioAppInput?.isReadyForMoreMediaData ?? false else { return }
                self.audioAppInput?.append(cmSampleBuffer)
            default: break
                
            }
        }, completionHandler: { [weak self] error in
            self?.startCompletedHandler?(error)
        })
    }
    
    private func startSession(_ sample: CMSampleBuffer, type: RPSampleBufferType) {
        guard let writer = self.assetWriter else { return }
        guard type == .video, writer.status == .unknown else { return }
        guard writer.startWriting() else { return }
        let cmTime = CMSampleBufferGetPresentationTimeStamp(sample)
        self.assetWriter?.startSession(atSourceTime: cmTime)
        self.currentState = .recroding
    }
}

extension ScreenRecordingManager {
    private func stopCapture() {
        print(#function)
        screenRecorder.stopCapture { error in
            guard error != nil else { return }
            self.currentState = .recroding
        }
        
        self.currentState = .stop
    }
    
    func stopRecording() {
        print(#function)
        stopCapture()
        guard let path = videoSavedPath else { return }
        guard assetWriter?.status != .unknown else { return }
        videoInput?.markAsFinished()
        audioAppInput?.markAsFinished()
        audioMicInput?.markAsFinished()
        
        assetWriter?.finishWriting { [weak self] in
            self?.currentState = .saveVideo
            self?.saveVideo(path)
        }
    }
    
    private func saveVideo(_ videoPath: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoPath)
        }) { (isSaved, error) in
            if isSaved {
                print(" Success Save Vodeo")
                self.currentState = .completed
            }
            
            if let error = error {
                print(" Save Error : \(error)")
            }
        }
    }
}

extension ScreenRecordingManager {
    private func createPath(to fileExtension: String) -> URL {
        let fileName = "record".dateFileName("\(fileExtension)")
        return  self.docuementPath.appendingPathComponent(fileName)
    }
}
