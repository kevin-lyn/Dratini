Pod::Spec.new do |s|
  s.name = 'Ditto-Swift'
  s.version = '1.0.2'
  s.license = 'MIT'
  s.summary = 'Serialize swift object to JSON object'
  s.homepage = 'https://github.com/kevin0571/Ditto'
  s.authors = { 'Kevin Lin' => 'kevin_lyn@outlook.com' }
  s.source = { :git => 'https://github.com/kevin0571/Ditto.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.source_files = 'Sources/*.swift'
  s.module_name = 'Ditto'
end
