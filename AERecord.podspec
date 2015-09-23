Pod::Spec.new do |s|
s.name = 'AERecord'
s.version = '2.0.0'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'Super awesome Core Data wrapper in Swift (for iOS and OSX)'

s.homepage = 'https://github.com/tadija/AERecord'
s.author = { 'tadija' => 'tadija@me.com' }
s.social_media_url = 'http://twitter.com/tadija'

s.source = { :git => 'https://github.com/tadija/AERecord.git', :tag => 'AERecord-v'+String(s.version) }
s.source_files = 'AERecord/*.swift'
s.ios.deployment_target = '8.0'
s.osx.deployment_target = '10.10'
end