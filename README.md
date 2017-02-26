# GameSoundEngine

## About
A simple, easy to use sound engine written in Swift, designed for iOS games. It supports playing background music and multiple simultaneous sound effects. To help ensure sonic variety, sound effects can be played with random pitch and volume levels, as well as randomly from a group of sound effects. 

## Installation
The GameSoundEngine framework can be installed using CocoaPods. Add the following line to your project pod file and the run "pod install".

```text
	pod 'GameSoundEngine', '~> 1.1.0'
```

## Using GameSoundEngine

#### Importing the framework
All Swift source files that reference the GameSoundEngine framework will need the following import statement:

```swift
	import GameSoundEngine
```

#### Sound Engine Initialization
The Sound Engine needs to be initialized once per app session so that it can configure and setup its background music player and sound effect players. This should be done in your App Delegate didFinishLaunchingWithOptions method before any UI is displayed:

```swift
	SoundEngine.shared.startEngine()
```

or

```swift
	SoundEngine.shared.startEngine(numSFXPlayers: 20)
```

The optional numSFXPlayers parameter allows you to specify the number of sound effect players configured by the sound engine. The default value is 20 which should be sufficient for most games. But if your game needs to play large numbers of sounds simultaneously you may need to increase this number. The sound engine will let you know if numSFXPlayers needs to be increased by displaying the following message in the console:

```text
	All sfx players are busy. Increase numSFXPlayers in startEngine call
```

In addition to configuring sound and music players, the startEngine call also configures your app's audio session using AVAudioSession. It also creates notification listeners so that it can pause and resume sounds as needed when events such as a phone call, or Siri occur. The audio session is configured to have the following behavior as recommended by Apple's audio guidelines for game apps:

  - Silenced by the Ring/Silent switch and by screen locking
  - Pauses all audio when an audio interruption (e.g. phone call, Siri, etc.) occurs
  - Resumes audio when the audio interruption has ended
  - Play sound effects while allowing another app’s audio (i.e. the Music app) to play.
  - Play background music when other audio is not playing, otherwise allow the previous audio to play.

#### Setting Overall Volume
The master volume for background music and the master volume for all sound effects are controlled through two properties on SoundEngine object:

```swift
	SoundEngine.shared.backgroundMusicVolume = 1.0
	SoundEngine.shared.sfxVolume = 1.0
```

Valid values for the volume properties are 0.0 - 1.0, with 0.0 being no volume and 1.0 full volume.

#### Background Music
Background music can be played by calling the playBackgroundMusic method on the SoundEngine object:

```swift
	SoundEngine.shared.playBackgroundMusic("backgroundMusic.m4a", loop: true)
```

The loop parameter is optional and defaults to true when not present.

To stop the background music call stopBackgroundMusic:

```swift
	SoundEngine.shared.stopBackgroundMusic(fadeOut: true)
```

The fadeOut parameter is optional and defaults to true.

Note that only one background music file can be played at a time. Calling playBackgroundMusic while background music is already playing will stop the current music before starting the new background music.

GameSoundEngine can also play a random selection from an array of background music files. 

```swift
	SoundEngine.shared.playRandomBackgroundMusic(["music1.m4a", "music2.m4a", "music3.m4a"], loop: true)
```

If the loop parameter is set to true, each loop will play a different random selection from the array of music files.

#### Sound Effects
To play a sound effect you first need to create an instance of the SoundSFX class specifying the name of the sound file resource in the initializer:

```swift
	let fireworkSound = SoundSFX("fireworkA.caf")
```

When the SoundSFX object is created, its initializer will preload the sound data from the resource file and load it into a data buffer so it is ready to play (the preloading is done on a background thread). The buffer will be released when the SoundSFX object goes out of scope and is released. This ensures low latency when playing the sound as the data is already loaded into memory before it is played. The best practice is to create your SoundSFX objects when your scene or view is initialized and then release the objects when the scene is released and the sounds are no longer needed.

To play a SoundSFX, simply call the play method on SoundSFX object:

```swift
	fireworkSound.play()
```

The volume for each SoundSFX can be set using an optional parameter in the initializer. The default value is 1.0.

```swift
	let fireworkSound = SoundSFX("fireworkA.caf", volume: 1.0)
```

#### Sound Effect Sonic Variety
Sound effects that are repeated over and over during a game can become very repetitive to users. To help solve this problem SoundSFX objects can be configured to allow the sound engine to randomly set a different volume and pitch for the SoundSFX each time it is played. This will help prevent the sounds from becoming too repetitive. The amount the volume and pitch can randomly vary is controlled through optional parameters in the SoundSFX initializer:

```swift
	let fireworkSound = SoundSFX("fireworkA.caf", volume: 1.0, volumeVary: 2.0, pitchVary: 100.0)
```

The volumeVary value is specified in dbs. A value of 2.0 indicates that the volume can randomly vary +/- 2 dbs from the base volume specified in the volume parameter. The pitchVary is specified in cents (1 musical semitone = 100 cents, 1 octave = 1200 cents). A value of 100.0 indicates that the pitch can very +/- 100 cents.

The framework contains some predefined constants that contain recommended values for the volumeVary and pitchVary values. These are good starting points, but any value can be specified.

```swift
	public let kVolumeVaryLow: Float = 1       // 1 db
	public let kVolumeVaryMedium: Float = 2    // 2 db
	public let kVolumeVaryLarge: Float = 3     // 3 db

	public let kPitchVaryLow: Float = 100      // 1 semitone
	public let kPitchVaryMedium: Float = 200   // 2 semitone
	public let kPitchVaryLarge: Float = 300    // 3 semitone
```

GameSoundEngine also supports randomly playing different variations of the same sound affect for even more sonic variety. For example if I have 3 different variations of the firework sound I can have the sound engine randomly pick one of the three different variations each time the effect is played. To accomplish this create an instance the RandomSoundSFX class and specify an array of SoundSFX objects:

```swift
    let fireworkSound = RandomSoundSFX([
        SoundSFX("fireworkA.caf", volume: 1.0, volumeVary: kVolumeVaryLarge, pitchVary:kPitchVaryLow),
        SoundSFX("fireworkB.caf", volume: 1.0, volumeVary: kVolumeVaryLarge, pitchVary:kPitchVaryLow),
        SoundSFX("fireworkC.caf", volume: 0.3, volumeVary: kVolumeVaryLarge, pitchVary:kPitchVaryLarge)
    ])
```

Now every time `fireworkSound.play()` is called the sound engine will randomly play either fireworkA.caf, fireworkB.caf, or fireworkC.caf. Note that the volume and pitch are also randomly varied as specified in the SoundSFX vary parameters. The overall effect creates a lot of sonic variety.

#### Playing Sound Effects as SpriteKit Actions
The framework also includes an extension to SpriteKit SKAction to allow playing SoundSFX objects as an SKAction. This makes it easier to synchronization the SoundSFX with animations in SKAction sequences and groups.

```swift
	let fireWorkSoundAction = SKAction.playSoundSFX(fireworkSound)
```

The parameter for the playSoundSFX method can be either a SoundSFX or a RandomSoundSFX object. Whenever the action is run, the sound effect will play.

#### Sound File Formats
Because the GameSoundEngine framework uses AVAudioEngine it can support any file format supported by Core Audio. However the following formats are generally recognized as good formats for iOS games due to their efficient decoding, low CPU impact and good sound quality:

For background music: MPEG 4 Audio format, AAC. To convert a file to this format use the `afconvert` console command:

```text
	afconvert -f m4af -d aac input_file
```

For sound effects: CAF format, linear PCM, little-endian, 16-bit. To convert a file to this format use the `afconvert` console command:

```text
	afconvert -f caff -d LEI16 input_file
```


## License
Copyright 2016 Endless Wave Software LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

