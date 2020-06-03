//
//  ScreenRecordingViewController.swift
//  ReplaykitExmaple
//
//  Created by jhjo on 2020/06/02.
//  Copyright © 2020 jhjo. All rights reserved.
//

import UIKit
import Photos

class ScreenRecordingViewController: UIViewController {
    
    private enum ButtonTyep: Int {
        case start = 0
        case stop = 1
        case pause = 2
    }
    
    private struct Color {
        static let pantone19_4052: UIColor = UIColor(displayP3Red: 15, green: 76, blue: 129, alpha: 1.0)
    }
    
    @IBOutlet private weak var secondLabel: UILabel!
    
    private let screenRecordingManager = ScreenRecordingManager.shared
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPhotoLibraryAuthorization()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard var second = Int(self.secondLabel.text ?? "0") else { return }
            second += 1
            self.secondLabel.text = String(second)
        }
    }
    
    @IBAction func tapButton(_ sender: UIButton) {
        guard let type = ButtonTyep(rawValue: sender.tag) else { return }
        
        switch type {
        case .start:
            screenRecordingManager.setupRecorder()
            screenRecordingManager.start()
        case .pause: break
        case .stop:
            screenRecordingManager.stopRecording()
        }
    }
}

extension ScreenRecordingViewController {
    
    private func getPhotoLibraryAuthorization() {
        PHPhotoLibrary.requestAuthorization { state in
            print(state)
        }
    }
}
