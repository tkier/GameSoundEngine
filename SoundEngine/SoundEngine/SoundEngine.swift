//
//  SoundEngine.swift
//
//  Created by Tom Kier on 12/21/16.
//  Copyright © 2016 Endless Wave Software LLC. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation
import AVFoundation

/// A simple, easy to use sound engine designed for iOS games
public class SoundEngine {
    
    public static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let backgroundMusicPlayer = AVAudioPlayerNode()
    private let sfxMixer = AVAudioMixerNode()
    private var alreadyStarted = false
    
    private var numSFXPlayers = 20
    private var playerNodes = [AVAudioPlayerNode]()
    private var pitchNodes = [AVAudioUnitTimePitch]()
    private var activePlayerIndex = 0
    
    private var fadeOutDisplayLink : CADisplayLink?
    private var fadeOutStartTime = 0.0
    private var fadeOutStartVolume = 1.0
    private let fadeOutLength = 1.5
    
    private init() { }
    
    /// Volume control for background music. Valid values are 0.0 - 1.0
    public var backgroundMusicVolume: Float = 1.0 {
        didSet {
            backgroundMusicPlayer.volume = backgroundMusicVolume
        }
    }
    
    /// Master volume for all sound effects. Valid values are 0.0 - 1.0
    public var sfxVolume: Float = 1.0 {
        didSet {
            sfxMixer.outputVolume = sfxVolume
        }
    }
    
    /**
     
       Configures the app's audio session and starts the sound engine. Should be called once,
       early during app start up, typically in the AppDelegate didFinishLaunchingWithOptions
     
       - Parameter numSFXPlayers: Specifies the number of sound effect players configured for playback. If your game needs to
                                  play large numbers of sounds simultaneously you may need to increase this number. The sound
                                  engine will let you know if numSFXPlayers needs to be increased by displaying the following
                                  message in the console: "All sfx players are busy. Increase numSFXPlayers in startEngine call"
     
    */
    public func startEngine(numSFXPlayers: Int = 20) {
        
        if alreadyStarted { return }
        alreadyStarted = true
        
        configureAudioSession()
        
        engine.attach(backgroundMusicPlayer)
        engine.connect(backgroundMusicPlayer, to: engine.mainMixerNode, format: nil)
        
        engine.attach(sfxMixer)
        engine.connect(sfxMixer, to: engine.mainMixerNode, format: nil)
        
        self.numSFXPlayers = numSFXPlayers
        for _ in 0..<numSFXPlayers {
            let player = AVAudioPlayerNode()
            playerNodes.append(player)
            let pitch = AVAudioUnitTimePitch()
            pitchNodes.append(pitch)
            
            engine.attach(player)
            engine.attach(pitch)
        }
        
        restartEngine()
    }
    
    /**
     
       Plays background music. Only one background music file may be played at a time. If background
       is already playing it will be stopped before the new music file is played.
     
       Parameters:
         - soundFile : The sound file name
         - loop      : When true will loop the sound file until the music is stopped or another music file is played.
    
    */
    public func playBackgroundMusic(_ soundFile: String, loop: Bool = true) {
        
        if !alreadyStarted {
            startEngine()
        }
        
        if AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint {
            backgroundMusicPlayer.volume = 0.0
        } else {
            backgroundMusicPlayer.volume = backgroundMusicVolume
        }
        
        if let path = Bundle.main.path(forResource: soundFile, ofType: nil) {
            let fileURL = NSURL.fileURL(withPath: path)
            if let file = try? AVAudioFile(forReading: fileURL) {
                stopFadeOut()
                backgroundMusicPlayer.stop()
                backgroundMusicPlayer.volume = backgroundMusicVolume
                if loop {
                    loopBackgroundMusic(file: file)
                } else {
                    backgroundMusicPlayer.scheduleFile(file, at: nil, completionHandler: nil)
                }
                backgroundMusicPlayer.play()
            }
        }
    }
    
    /**
     
       Stops the background music.
     
       Parameter fadeOut: When true will do a short fadeout of the music before stopping it completely.
                          If false the music will stop immediately.
     
    */
    public func stopBackgroundMusic(fadeOut: Bool = true) {
        
        if backgroundMusicPlayer.isPlaying {
            if fadeOut {
                startFadeOut()
            } else {
                backgroundMusicPlayer.stop()
            }
        }
    }

    
    private func configureAudioSession() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch {
            
        }
        
        let nc = NotificationCenter.default
        nc.addObserver(forName:NSNotification.Name.AVAudioSessionSilenceSecondaryAudioHint,
                       object:nil,
                       queue:nil,
                       using:catchAudioHintNotification)
        
        nc.addObserver(forName:NSNotification.Name.AVAudioSessionInterruption,
                       object:nil,
                       queue:nil,
                       using:catchAudioSessionInterruptionNotification)
        
        nc.addObserver(forName:NSNotification.Name.UIApplicationDidBecomeActive,
                       object:nil,
                       queue:nil,
                       using:catchDidBecomeActiveNotification)
    }
    
    private func catchAudioHintNotification(notification:Notification) -> Void {
        
        guard let userInfo = notification.userInfo,
            let audioHintType  = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
            let audioHint = AVAudioSessionSilenceSecondaryAudioHintType(rawValue:audioHintType)
            else { return }
        
        switch audioHint {
        case .begin:
            backgroundMusicPlayer.volume = 0.0
            break
        case .end:
            backgroundMusicPlayer.volume = backgroundMusicVolume
            break
        }
    }
    
    private func catchAudioSessionInterruptionNotification(notification:Notification) -> Void {
        
        guard let userInfo = notification.userInfo,
            let interruptionType  = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruption = AVAudioSessionInterruptionType(rawValue:interruptionType)
            else { return }
        
        switch interruption {
        case .began:
            engine.pause()
            break
        case .ended:
            restartEngine()
            break
        }
    }
    
    private func catchDidBecomeActiveNotification(notification:Notification) -> Void {
        
        restartEngine()
    }
    
    private func restartEngine() {
        
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("AVAudioEngine did not start")
            }
        }
        
        if AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint {
            backgroundMusicPlayer.volume = 0.0
        } else {
            backgroundMusicPlayer.volume = backgroundMusicVolume
        }
    }
    
    internal func loadSound(soundFile: String,
                   volume: Float,
                   volumeVary: Float? = nil,
                   pitchVary: Float? = nil,
                   completionHandler: @escaping ((() -> Void)?) -> Void)
    {
        var playClosure : (() -> Void)? = nil
        
        if !alreadyStarted {
            startEngine()
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            if let path = Bundle.main.path(forResource: soundFile, ofType: nil) {
                let fileURL = NSURL.fileURL(withPath: path)
                
                if let file = try? AVAudioFile(forReading: fileURL) {
                    let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
                    do {
                        try file.read(into: buffer)
                    } catch _ {
                        completionHandler(nil)
                        return
                    }
                    
                    var maxVolume : Float?
                    var minVolume : Float?
                    if let db = volumeVary {
                        maxVolume = round(1000000000.0 * pow(10.0, db/20.0)) / 1000000000.0
                        minVolume = round(1000000000.0 * pow(10.0, -db/20.0)) / 1000000000.0
                    }
                    
                    playClosure = { [weak self] in
                        self?.playBufferOnNextAvailablePlayer(buffer: buffer,
                                                              volume: volume,
                                                              minVolume: minVolume,
                                                              maxVolume: maxVolume,
                                                              pitchVary: pitchVary)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completionHandler(playClosure)
            }
        }
    }
    
    private func playBufferOnNextAvailablePlayer(buffer: AVAudioPCMBuffer,
                                                 volume: Float,
                                                 minVolume : Float?,
                                                 maxVolume : Float?,
                                                 pitchVary: Float?)
    {
        var numPlayersChecked = 0
        var player = playerNodes[activePlayerIndex]
        while player.isPlaying {
            activePlayerIndex += 1
            if activePlayerIndex == numSFXPlayers {
                activePlayerIndex = 0
            }
            player = playerNodes[activePlayerIndex]
            
            numPlayersChecked += 1
            if numPlayersChecked > numSFXPlayers {
                print("All sfx players are busy. Increase numSFXPlayers in startEngine call")
                return
            }
        }
        
        if let min = minVolume, let max = maxVolume {
            player.volume = volume * Float(Int.random(min: Int(min * 100), max: Int(max * 100))) / 100.0
        } else {
            player.volume = volume
        }
        
        let pitch = pitchNodes[activePlayerIndex]
        if let cents = pitchVary {
            pitch.pitch = Float(Int.random(min: Int(-cents * 100.0), max: Int(cents * 100.0))) / 100.0
            
            engine.connect(player, to: pitch, format: buffer.format)
            engine.connect(pitch, to: sfxMixer, format: buffer.format)
        } else {
            engine.connect(player, to: sfxMixer, format: buffer.format)
        }
        
        player.scheduleBuffer(buffer, completionHandler:{ [weak self] in
            DispatchQueue.main.async {
                player.stop()
                self?.engine.disconnectNodeOutput(pitch)
                self?.engine.disconnectNodeOutput(player)
            }
        })
        player.play()
    }
    
    private func loopBackgroundMusic(file: AVAudioFile) {
        
        backgroundMusicPlayer.scheduleFile(file, at: nil, completionHandler: { [weak self] in
            self?.loopBackgroundMusic(file: file)
        })
    }
    
    private func startFadeOut() {
        
        stopFadeOut()
        
        fadeOutStartTime = CACurrentMediaTime()
        fadeOutStartVolume = Double(backgroundMusicPlayer.volume)
        
        fadeOutDisplayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        fadeOutDisplayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    @objc private func displayLinkDidFire() {
        
        let elapsed = CACurrentMediaTime() - fadeOutStartTime
        
        if elapsed >= fadeOutLength {
            stopFadeOut()
            backgroundMusicPlayer.stop()
            return
        }
        
        let percentComplete = elapsed / fadeOutLength
        backgroundMusicPlayer.volume = Float(fadeOutStartVolume - fadeOutStartVolume * percentComplete)
    }
    
    private func stopFadeOut() {
        
        fadeOutDisplayLink?.invalidate()
        fadeOutDisplayLink = nil
    }
}
