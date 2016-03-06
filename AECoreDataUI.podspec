Pod::Spec.new do |s|
s.name = 'AECoreDataUI'
s.version = '2.0.1'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'Super awesome Core Data driven UI in Swift (for iOS)'

s.homepage = 'https://github.com/tadija/AERecord'
s.author = { 'tadija' => 'tadija@me.com' }
s.social_media_url = 'http://twitter.com/tadija'

s.source = { :git => 'https://github.com/tadija/AERecord.git', :tag => 'AECoreDataUI-v'+String(s.version) }
s.source_files = 'AECoreDataUI/*.swift'
s.ios.deployment_target = '8.0'
end
