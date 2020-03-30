Pod::Spec.new do |s|
  s.name         = 'UPnAtom'
  s.version      = '0.8.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'An open source Universal Plug and Play library with a focus on media streaming coordination using the UPnP A/V profile.'
  s.homepage     = 'https://github.com/master-nevi/UPnAtom'
  s.authors      = { 'David Robles' => 'master-nevi@users.noreply.github.com' }
  s.source       = { :git => 'https://github.com/master-nevi/UPnAtom.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.swift_version = '5.0'

  s.source_files = 'Source/**/*.swift'
  s.exclude_files = 'Source/CocoaSSDP Support/*.swift'
  s.dependency 'CocoaAsyncSocket', '>= 7.4.1' # UPnP object discovery using SSDP
  s.dependency 'AFNetworking/Serialization', '>= 3.1' # HTTP Client
  s.dependency 'AFNetworking/Security', '>= 3.1' # HTTP Client
  s.dependency 'AFNetworking/Reachability', '>= 3.1' # HTTP Client
  s.dependency 'AFNetworking/NSURLSession', '>= 3.1' # HTTP Client
  s.dependency 'Ono', '>= 1.2.0' # XML parsing
  s.dependency 'GCDWebServer', '>= 3.3' # UPnP event notification handling
end
