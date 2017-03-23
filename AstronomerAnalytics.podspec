Pod::Spec.new do |s|
  s.name             = "AstronomerAnalytics"
  s.version          = "3.6.0"
  s.summary          = "The hassle-free way to add analytics to your iOS app."

  s.description      = <<-DESC
                       Analytics for iOS provides a single API that lets you
                       integrate with over 100s of tools.
                       DESC

  s.homepage         = "http://astronomer.io/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "Astronomer" => "info@astronomer.io" }
  s.source           = { :git => "https://github.com/astronomerio/analytics-ios.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/astronomerio'

  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.framework = 'Security'

  s.source_files = 'Analytics/Classes/**/*'
end
