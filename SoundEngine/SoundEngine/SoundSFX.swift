//
//  SoundSFX.swift
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
import SpriteKit

@objc public protocol PlayableSoundSFX {
    func play()
}

public let kVolumeVaryLow: Float = 1       // 1 db
public let kVolumeVaryMedium: Float = 2    // 2 db
public let kVolumeVaryLarge: Float = 3     // 3 db

public let kPitchVaryLow: Float = 100      // 1 semitone
public let kPitchVaryMedium: Float = 200   // 2 semitone
public let kPitchVaryLarge: Float = 300    // 3 semitone

/// Sound effect class for playing a short sound.
open class SoundSFX : NSObject, PlayableSoundSFX {
    
    private var playSound: (() -> Void)?
    private var playOnLoad = false
    
    /**
     
        Initializes a sound effect. When initialized loads the sound data from file and stores it into a buffer. The
        buffer is kept in memory for the lifetime of the SoundSFX object. The sound effect can play over and over, but
        its data is only loaded once at initialization time.
     
        - Parameters:
            - soundFile: The resource file that contains sound data (caf format recommneded)
            - volume: The base volume that the sound effect will be played at. Valid values are 0.0 - 1.0.
            - volumeVary: The amount the volume should randomly vary when played. Specified in dbs.
            - pitchVary: The amount the pitch should randomly vary when played. Specified in cents (1 musical semitone = 100 cents, 1 octave = 1200 cents).
    
    */
    @objc public init(_ soundFile: String, volume: Float = 1.0, volumeVary: NSNumber? = nil, pitchVary: NSNumber? = nil) {
        super.init()
        SoundEngine.shared.loadSound(soundFile: soundFile,
                                     volume: volume,
                                     volumeVary: volumeVary?.floatValue,
                                     pitchVary: pitchVary?.floatValue,
                                     completionHandler: { [weak self] playCallBack in
                                         guard let strongSelf = self else { return }
                                         strongSelf.playSound = playCallBack
                                         if strongSelf.playOnLoad, let play = playCallBack {
                                             play()
                                         }
                                     })
    }
    
    /// Plays the sound effect.
    open func play() {
        if let playSound = playSound {
            playSound()
        } else {
            playOnLoad = true
        }
    }
}

/// A sound effect class that randomly plays a sound effect from a list of sound effects.
open class RandomSoundSFX : PlayableSoundSFX {
    
    private var effects : [SoundSFX]

    /**
     
     Creates a playable sound effect that randomly plays one sound effect from a list of sound effects. Each time
     this sound effect is played it randony selects one of SoundSFX objects from the list of effects specified in the 
     initailizer and plays that effect.
     
     - Parameter effects: Array of SoundSFX ojbects
     
    */
    public init(_ effects: [SoundSFX]) {
        self.effects = effects
    }
 
    /// Plays the sound effect.
    open func play() {
        effects[Int.random(effects.count)].play()
    }
}

public extension SKAction {
    
    /**
     
        Creates a SKAction that when run will play a SoundSFX or RandomSoundSFX object.
     
        - Parameter soundSFX: The SoundSFX or RandomSoundSFX object to be played.
    
    */
    public class func playSoundSFX(_ soundSFX: PlayableSoundSFX) -> SKAction {
        return SKAction.run({ 
            soundSFX.play()
        })
    }
}

