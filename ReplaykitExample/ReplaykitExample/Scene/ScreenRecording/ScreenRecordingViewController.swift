//
//  ScreenRecordingViewController.swift
//  ReplaykitExmaple
//
//  Created by jhjo on 2020/06/02.
//  Copyright © 2020 jhjo. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

extension ScreenRecordingViewController {
    private enum ButtonTyep: Int {
        case start = 0
        case stop = 1
        case pause = 2
        case audioStart = 3
    }
    
    private struct Color {
        static let pantone19_4052: UIColor = UIColor(displayP3Red: 15, green: 76, blue: 129, alpha: 1.0)
    }
}

class ScreenRecordingViewController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet private weak var secondLabel: UILabel!
    @IBOutlet private weak var currentStateLabel: UILabel!
    
    // MARK: - property
    
    private let screenRecordingManager = ScreenRecordingManager.shared
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPhotoLibraryAuthorization()
        setupAudioPlayer()
        setupScreenRecordingManager()
    }
    
    // MARK: - IBAction
    
    @IBAction private func tapButton(_ sender: UIButton) {
        guard let type = ButtonTyep(rawValue: sender.tag) else { return }
        print(type)
        switch type {
        case .start:
            screenRecordingManager.setupRecorder()
            screenRecordingManager.start()
            setupTimer()
        case .pause: break
        case .stop:
            screenRecordingManager.stopRecording()
        case .audioStart:
            audioPlayer?.play()
        }
    }
}

// MARK: - setup
extension ScreenRecordingViewController {
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
             guard let self = self else { return }
             guard var second = Int(self.secondLabel.text ?? "0") else { return }
             second += 1
             self.secondLabel.text = String(second)
         }
    }
    
    private func setupAudioPlayer() {
        let url = Bundle.main.url(forResource: "Sound", withExtension: ".m4a")!
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue)
            audioPlayer?.prepareToPlay()
        } catch (let error) {
            print("error : \(error)")
        }
    }
    
    private func setupScreenRecordingManager() {
        screenRecordingManager.currentStateHandler = { [weak self] state in
             guard let self = self else { return }
             DispatchQueue.main.async {
                 self.currentStateLabel.text = state.rawValue
                 if state == .completed, (self.timer?.isValid ?? false) {
                     self.timer?.invalidate()
                     self.audioPlayer?.stop()
                 }
             }
         }
    }
}

// MARK: - Function
extension ScreenRecordingViewController {
    
    private func getPhotoLibraryAuthorization() {
        PHPhotoLibrary.requestAuthorization { state in
            print(state)
        }
    }
}
