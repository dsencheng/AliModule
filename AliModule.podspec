#
# Be sure to run `pod lib lint AliModule.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AliModule'
  s.version          = '0.1.0'
  s.summary          = '阿里SDK集成.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  集成阿里推送，RTC视频聊天
                       DESC

  s.homepage         = 'https://github.com/dsencheng/AliModule'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dsencheng' => 'dsencheng@gmail.com' }
  s.source           = { :git => 'https://github.com/dsencheng/AliModule.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'AliModule/Classes/**/*.{h,m}'
  s.exclude_files = 'AliModule/Classes/**/*.{framework, modulemap, plist}'
  # s.resource_bundles = {
  #   'AliModule' => ['AliModule/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.ios.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC', 'ENABLE_BITCODE' => false, }
  s.frameworks = 'UIKit','AudioToolbox', 'VideoToolbox','CoreVideo','CoreMedia','OpenGLES','AVFoundation','CoreTelephony','SystemConfiguration'
  s.library = 'c++', 'resolv'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.ios.vendored_framework = 'AliModule/Classes/Ali/UTDID.framework'
  s.subspec 'AliRTC' do | sub_rtc |
      sub_rtc.ios.vendored_framework = 'AliModule/Classes/Ali/AliRTCSdk.framework'
      #sub_rtc.source_files = 'AliModule/Classes/RTC/*'
  end
  s.subspec 'AliPush' do | sub_push |
      sub_push.ios.frameworks = 'UserNotifications'
      sub_push.ios.vendored_frameworks = ['AliModule/Classes/Ali/AlicloudUtils.framework','AliModule/Classes/Ali/CloudPushSDK.framework','AliModule/Classes/Ali/UTMini.framework']
      
  end
  
  
end
