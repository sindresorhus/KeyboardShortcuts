Pod::Spec.new do |s|
	s.name = 'KeyboardShortcuts'
	s.version = '0.2.2'
	s.summary = 'Add user-customizable global keyboard shortcuts to your macOS app in minutes'
	s.license = 'MIT'
	s.homepage = 'https://github.com/sindresorhus/KeyboardShortcuts'
	s.social_media_url = 'https://twitter.com/sindresorhus'
	s.authors = { 'Sindre Sorhus' => 'sindresorhus@gmail.com' }
	s.source = { :git => 'https://github.com/sindresorhus/KeyboardShortcuts.git', :tag => "v#{s.version}" }
	s.source_files = 'Sources/**/*.swift'
	s.swift_version = '5.2'
	s.platform = :macos, '10.11'
	s.weak_framework = 'Combine'
end
