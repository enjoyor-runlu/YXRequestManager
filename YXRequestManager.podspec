#
# Be sure to run `pod lib lint YXRequestManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YXRequestManager'
  s.version          = '1.1.6'
  s.summary          = 'YXRequestManager.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://www.baidu.com/'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jiaguoshang' => 'jia12216@163.com' }
  s.source           = { :git => 'https://github.com/enjoyor-runlu/YXRequestManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

   s.source_files  = 'YXRequestManager/Classes/**/*.{h,m}'
#  s.source_files = 'YXCache', 'YXRequestManager/Classes/YXCache/*.{h,m}',
#  s.source_files = 'AESCategory', 'YXRequestManager/Classes/AESCategory/*.{h,m}'
#  s.source_files = 'YXRequest', 'YXRequestManager/Classes/YXRequest/*.{h,m}'
#s.source_files  = "YXRequestManager", "YXRequestManager/**/*.{h,m}"

   s.resource_bundles = {
      'YXRequestManager' => ['YXRequestManager/Classes/*.xcassets']
   }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit', 'Foundation'
   s.dependency 'YXFDCategories'
   s.dependency 'AFNetworking', '3.1.0'
   s.dependency 'TMCache'
end
