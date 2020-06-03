//
//  ScreenRecordingManager.swift
//  ReplaykitExmaple
//
//  Created by Bruce on 2020/06/03.
//  Copyright © 2020 jhjo. All rights reserved.
//

import ReplayKit

class ScreenRecordingManager {
    static let shared = ScreenRecordingManager()
    
    private var docuementPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private let screenRecorder = RPScreenRecorder.shared()
    
    private var videoSavedPath: URL?
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioMicInput: AVAssetWriterInput?
    private var audioAppInput: AVAssetWriterInput?
    
    
}


extension ScreenRecordingManager {
    func setupRecorder() {
        if screenRecorder.isRecording {
            
        }
    }
    
    private func setupVideoAssetWriter() {
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
    
}

extension ScreenRecordingManager {
    private func createPath(to fileExtension: String) -> URL {
        let fileName = "record".dateFileName("\(fileExtension)")
        return  self.docuementPath.appendingPathComponent(fileName)
    }
}
