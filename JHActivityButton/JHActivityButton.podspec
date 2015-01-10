#
# Be sure to run `pod lib lint JHActivityButton.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "JHActivityButton"
  s.version          = "1.0.0"
  s.summary          = "Animated UIButton Subclass with a built-in UIActivityIndicator."
  s.description      = "UIButton Subclass with a built-in UIActivityIndicator. Based off the Ladda concept by Hakim El Hattab http://lab.hakim.se/ladda"
  s.homepage         = "https://github.com/justinHowlett/JHActivityButton"
  s.license          = 'MIT'
  s.author           = { "Justin Howlett" => "justin@justinhowlett.com" }
  s.source           = { :git => "https://github.com/justinHowlett/JHActivityButton.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.frameworks = 'CoreGraphics'
  s.dependency 'AHEasing', '~> 1.1'
  s.dependency 'Masonry'

end
