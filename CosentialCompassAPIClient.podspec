Pod::Spec.new do |s|
  s.name             = 'CosentialCompassAPIClient'
  s.version          = '0.6.4'
  s.summary          = 'CosentialCompassAPIClient'
 
  s.description      = <<-DESC
CosentialCompassAPIClient for Pod
                       DESC
 
  s.homepage         = 'https://github.com/cosential/compass-client-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Cosential Compass'
  s.source           = { :git => 'https://github.com/cosential/compass-client-swift.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '10.0'
  s.dependency 'Alamofire', '~> 4.0'
  s.source_files = 'CosentialCompassAPIClient/*.swift'
 
end
