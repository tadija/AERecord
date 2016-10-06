Pod::Spec.new do |s|

    s.name = 'AERecord'
    s.summary = 'Super awesome Core Data wrapper (for iOS, OSX, tvOS) written in Swift'
    s.version = '4.0.0'
    s.license = { :type => 'MIT', :file => 'LICENSE' }

    s.homepage = 'https://github.com/tadija/AERecord'
    s.author = { 'tadija' => 'tadija@me.com' }
    s.social_media_url = 'http://twitter.com/tadija'

    s.source = { :git => 'https://github.com/tadija/AERecord.git', :tag => s.version }
    s.source_files = 'Sources/*.swift'

    s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }

    s.ios.deployment_target = '8.0'
    s.tvos.deployment_target = '9.0'
    s.osx.deployment_target = '10.10'

end
