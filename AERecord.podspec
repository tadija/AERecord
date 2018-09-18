Pod::Spec.new do |s|

s.name = 'AERecord'
s.version = '4.1.2'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'Super awesome Swift minion for Core Data (iOS, macOS, tvOS)'

s.source = { :git => 'https://github.com/tadija/AERecord.git', :tag => s.version }
s.source_files = 'Sources/AERecord/*.swift'

s.swift_version = '4.2'

s.ios.deployment_target = '8.0'
s.watchos.deployment_target = '2.2'
s.tvos.deployment_target = '9.2'
s.osx.deployment_target = '10.11'

s.homepage = 'https://github.com/tadija/AERecord'
s.author = { 'tadija' => 'tadija@me.com' }
s.social_media_url = 'http://twitter.com/tadija'

end
