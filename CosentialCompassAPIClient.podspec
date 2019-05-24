Pod::Spec.new do |s|
  s.name             = 'CosentialCompassAPIClient'
  s.version          = '1.0.7'
  s.summary          = 'CosentialCompassAPIClient'
 
  s.description      = <<-DESC
CosentialCompassAPIClient for Pod
                       DESC
 
  s.homepage         = 'https://github.com/cosential/compass-client-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Cosential Compass'
  s.source           = { :git => 'https://github.com/cosential/compass-client-swift.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '12.1'
  s.dependency 'Alamofire', '~> 4.0'
  s.source_files = 'CosentialCompassAPIClient/*.swift'

  s.swift_version = "4.2"
 
end
