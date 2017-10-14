Pod::Spec.new do |s|
	s.name         = "SHNUrlRouter"
	s.version      = "1.3.0"
	s.summary      = "Simple Router for Swift"
	s.homepage     = "https://github.com/shnhrrsn/SHNUrlRouter"
	s.license      = "MIT"

	s.author       = "Shaun Harrison"
	s.social_media_url = "http://twitter.com/shnhrrsn"

	s.platform     = :ios, "8.0"

	s.ios.deployment_target  = "9.0"
	s.tvos.deployment_target = "9.0"

	s.source       = { :git => "https://github.com/shnhrrsn/SHNUrlRouter.git", :tag => s.version }

	s.source_files = "Sources/*.swift"
	s.requires_arc = true
end
