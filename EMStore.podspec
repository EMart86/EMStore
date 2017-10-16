#
# Be sure to run `pod lib lint EMStore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EMStore'
  s.version          = '1.0.2'
  s.summary          = 'A simple SQLite wrapper library for faster setup of core data'

  s.description      = <<-DESC
With thos library, you don't need to write all this ManagedObjectContext and Persistance Store Coordinator, because it does that for you. All you need to do is, to focus on your models
                       DESC

  s.homepage         = 'https://github.com/EMart86/EMStore'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eberl_ma@gmx.at' => 'martin.eberl@styria.com' }
  s.source           = { :git => 'https://github.com/EMart86/EMStore.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'EMStore/Classes/**/*'
end
