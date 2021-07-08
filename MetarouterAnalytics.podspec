Pod::Spec.new do |s|
  s.name             = "MetarouterAnalytics"
  s.module_name      = "Metarouter"
  s.version          = "4.1.7"
  s.summary          = "The hassle-free way to add analytics to your iOS app."

  s.description      = <<-DESC
                       Metarouter Analytics for iOS provides a single API that lets you
                       integrate with over 100s of tools.
                       DESC

  s.homepage         = "http://metarouter.io/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "Astronomer" => "info@metarouter.io" }
  s.source           = { :git => "https://github.com/metarouter/analytics-ios.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/metarouter'

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'

  s.source_files = [
    'Metarouter/Classes/**/*.{h,m}',
    'Metarouter/Internal/**/*.{h,m}'
  ]
end
