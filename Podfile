# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def common
  pod 'Firebase'
  pod 'FirebaseAuth'
  pod 'Firebase/Database'
  pod 'JSQMessagesViewController'

end

target 'FlatironChat' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  common
  pod 'SwiftyJSON'

  # Pods for FlatironChat

  target 'FlatironChatTests' do
    inherit! :search_paths
    common
    # Pods for testing
  end

end
