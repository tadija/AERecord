Pod::Spec.new do |s|
    s.name = 'AERecord'
    s.version = '3.0.0'
    s.summary = 'Super awesome Core Data wrapper (for iOS, OSX, tvOS) written in Swift'

    s.homepage = 'https://github.com/tadija/AERecord'
    s.license = { :type => 'MIT', :file => 'LICENSE' }
    s.author = { 'tadija' => 'tadija@me.com' }
    s.social_media_url = 'http://twitter.com/tadija'

    s.ios.deployment_target = '8.0'
    s.tvos.deployment_target = '9.0'
    s.osx.deployment_target = '10.10'

    s.source = { :git => 'https://github.com/tadija/AERecord.git', :tag => s.version }
    s.source_files = 'Sources/*.swift'
end