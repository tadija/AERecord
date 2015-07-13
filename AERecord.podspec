Pod::Spec.new do |s|
s.name = 'AERecord'
s.version = '1.1.0'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'Super awesome Core Data wrapper for iOS written in Swift'

s.homepage = 'https://github.com/tadija/AERecord'
s.author = { 'Marko Tadić' => 'tadija@me.com' }
s.social_media_url = 'http://twitter.com/tadija'

s.source = { :git => 'https://github.com/tadija/AERecord.git', :tag => s.version }
s.source_files = 'AERecord/*.swift'
s.ios.deployment_target = '8.0'
end