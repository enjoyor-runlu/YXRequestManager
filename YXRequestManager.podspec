Pod::Spec.new do |spec|
  spec.name             = 'YXRequestManager'
  spec.version          = '2.0.2'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage         = 'https://github.com/enjoyor-runlu/YXRequestManager'
  spec.author           = { '' => '' }
  spec.summary          = 'YXRequestManager.'
  spec.source           = { :git => 'https://github.com/enjoyor-runlu/YXRequestManager.git', :tag => spec.version.to_s }

  spec.ios.deployment_target = '8.0'
  
  spec.source_files  = 'YXRequestManager/Classes/**/*.{h,m}'
  spec.resource_bundles = {
     'YXRequestManager' => ['YXRequestManager/Classes/*.xcassets']
  }
  
  spec.frameworks = 'UIKit', 'Foundation'
  
  spec.dependency 'YXFDCategories'
  spec.dependency 'AFNetworking'
  spec.dependency 'TMCache'
end
