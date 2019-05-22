//
//  AudiobackgroundTask.swift
//
//  Created by Sisov on 5/21/19.
//  Copyright © 2019 Sisov. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: Background Audio
class AudioBackgroundTask {
  
  // MARK: Private properties
  private var bgTask: UIBackgroundTaskIdentifier = .invalid
  private var timer: Timer!
  private var audioPlayer: AVAudioPlayer!
  private var filePath: String!
  
  // MARK: Initialization
  init(_ filePath: String) {
    self.filePath = filePath    
  }
}

// MARK: Public functions
extension AudioBackgroundTask {
  func startBackgroundTask(_ time: Int, _ handle: @escaping(_ error: Error?)->Void) {
    initializationBackgroundTask(time, handle)
  }
  
  func stopbackgroundTask() {
    stopAudio()
  }
}

// MARK: Private functions
private extension AudioBackgroundTask {
  
  /// Function must be call in main thread
  /// - parameter time - The number of seconds between firings of the timer. If seconds is less than or equal to 0.0, this method chooses the nonnegative value of 0.1 milliseconds instead
  /// - parameter handke - The execution body of the timer; the timer itself is passed as the parameter to this block when executed to aid in avoiding cyclical references
  func initializationBackgroundTask(_ time: Int, _ handle: @escaping(_ error: Error?)->Void) {
    assert(Thread.isMainThread, "Background task should be initialized only in main thread...")
    
    if isRunning() {
      stopAudio()
    }
    
    while self.isRunning() {
      Thread.sleep(forTimeInterval: 10)
    }
    
    playAudio(time, handle)
  }
  
  func playAudio(_ time: Int, _ handle: @escaping(_ error: Error?)->Void) {
    
    NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { (notification) in
      guard let interuptionDic = notification.userInfo else { return }
      guard let type = interuptionDic[AVAudioSessionInterruptionTypeKey] as? Int else { return }
      if type == 1 {
        self.initializationBackgroundTask(time, handle)
      }
    }
    
    let app = UIApplication.shared
    bgTask = app.beginBackgroundTask(expirationHandler: {
      self.stopAudio()
    })
    
    do {
      try setSession()
      try setAudioPlayer()
    }
    catch {
      stopAudio()
      handle(error)
    }
    
    setTimer(time,handle)
  }
  
  func stopAudio() {
    NotificationCenter.default.removeObserver(self)
    
    if timer != nil {
      timer.invalidate()
      timer = nil
    }
    
    if audioPlayer != nil {
      audioPlayer.stop()
      audioPlayer = nil
    }
    
    if bgTask != .invalid {
      let app = UIApplication.shared
      app.endBackgroundTask(bgTask)
      bgTask = .invalid
    }
  }
  
  func isRunning() -> Bool {
    return bgTask != .invalid
  }
  
  func setSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .spokenAudio, options: .mixWithOthers)
    try session.setActive(true, options: .notifyOthersOnDeactivation)
  }
  
  func setAudioPlayer() throws {
    let url = URL(fileURLWithPath: filePath)
    audioPlayer = try AVAudioPlayer(contentsOf: url)
    audioPlayer.volume = 0.01
    audioPlayer.numberOfLoops = -1
    audioPlayer.prepareToPlay()
    audioPlayer.play()
  }
  
  func setTimer(_ time: Int,_ handle: @escaping(_ error: Error?)->Void) {
    timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(time), repeats: true, block: { (timer) in
      handle(nil)
    })
  }
}
