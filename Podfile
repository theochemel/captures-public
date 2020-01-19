# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'clipthat-standalone' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'SwiftyJSON', '~> 4.0'
  pod 'BrightFutures'
  pod 'Digger'
  pod 'KeychainSwift', '~> 11.0'
  pod 'Google-Mobile-Ads-SDK'
  pod 'SkeletonView'
  pod 'Hero'
  pod 'DateToolsSwift'
  pod 'Kingfisher', '~> 4.0'
  pod 'TransitionButton'

  # Pods for clipthat-standalone

end

post_install do |installer|
    print "Setting the default SWIFT_VERSION to 4.2\n"
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
    end
    
    installer.pods_project.targets.each do |target|
        if ['Hero', 'ABVideoRangeSlider'].include? "#{target}"
            print "Setting #{target}'s SWIFT_VERSION to 3.0\n"
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
            else
            print "Setting #{target}'s SWIFT_VERSION to Undefined (Xcode will automatically resolve)\n"
            target.build_configurations.each do |config|
                config.build_settings.delete('SWIFT_VERSION')
            end
        end
    end
end
