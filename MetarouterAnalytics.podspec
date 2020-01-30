Pod::Spec.new do |s|
  s.name             = "MetarouterAnalytics"
  s.version          = "3.8.0-beta.1"
  s.summary          = "The hassle-free way to add analytics to your iOS app."

  s.description      = <<-DESC
                       Metarouter Analytics for iOS provides a single API that lets you
                       integrate with over 100s of tools.
                       DESC

  s.homepage         = "http://metarouter.io/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "Astronomer" => "info@metarouter.io" }
  s.source           = { :git => "https://github.com/super-collider/analytics-ios.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/metarouter'

  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.ios.frameworks = 'CoreTelephony'
  s.frameworks = 'Security', 'StoreKit', 'SystemConfiguration', 'UIKit'

  s.source_files = [
    'Analytics/Analytics.h',
    'Analytics/Classes/**/*',
    'Analytics/Vendor/**/*'
  ]
end
