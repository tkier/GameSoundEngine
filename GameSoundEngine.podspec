#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #

  s.name         = "GameSoundEngine"
  s.version      = "1.0.0"
  s.summary      = "A simple, easy to use sound engine written in Swift, designed for iOS games."

  s.description  = "GameSoundEngine supports playing background music and multiple simultaneous sound effects. To help ensure sonic variety, sound effects can be played with random pitch and volume levels, as well as randomly from a group of sound effects."

  s.homepage     = "https://github.com/tkier/GameSoundEngine"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #

  s.license      = "Apache License, Version 2.0"
  

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #

  s.author             = { "Tom Kier" => "tom@endlesswavesoftware.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #

  s.platform     = :ios, "9.0"



  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #

  s.source       = { :git => "https://github.com/tkier/GameSoundEngine.git", :tag => "#{s.version}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
 
  s.source_files  = "SoundEngine/SoundEngine/*.{h,swift}"

end
