# Uncomment this line to define a global platform for your project

platform :ios, '9.3'
use_frameworks!                 # Add this if you are targeting iOS 8+ or using Swift

target 'Blah' do

  # Swift 2
  # pod 'CocoaAsyncSocket',   '~> 7.5.0'
  # pod 'CorePlot',           '~> 2.1.0'
  # pod 'InAppSettingsKit',   '~> 2.8.0'
  # pod 'MGSwipeTableCell',   '~> 1.5.5'
  # pod 'SwiftyDropbox',      '~> 3.2.0'
  # pod 'SwiftyUserDefaults', '~> 2.2.1'

  # Swift 3
  pod 'CircleProgressView', '~> 1.0'
  pod 'CorePlot', '~> 2.0'

  pod 'InAppSettingsKit', '~> 2.0'
  pod 'JSQCoreDataKit', '~> 6.0'
  pod 'SwiftyDropbox', '~> 4.0'

  target 'BlahTests' do
    inherit! :search_paths
  end
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.0'
      end
    end
  end
end
