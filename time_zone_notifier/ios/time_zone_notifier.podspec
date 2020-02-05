#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'time_zone_notifier'
  s.version          = '0.0.1'
  s.summary          = 'Un-implemented implementation to prevent build/run errors'
  s.description      = <<-DESC
No-op implementation of the iOS plugin to avoid build issues on iOS.
                       DESC
  s.homepage         = 'https://github.com/BobEvans/taqo_survey/tree/develop/time_zone_notifier'
  s.license          = { :file => '../LICENSE' }
  s.author           = { '' => '' }
  s.source           = { :git => '' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
