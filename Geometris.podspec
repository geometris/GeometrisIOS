
Pod::Spec.new do |s|

  s.name         = "Geometris"
  s.version      = "1.0.2"
  s.summary      = "Geometris Framework."
  s.description  = "Geometris OBDII device Interface"
  s.homepage     = "http://geometris.com"
  s.license      = "MIT"
  s.author       = "Geometris"
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/geometris/GeometrisIOS.git", :tag => "1.0.2" }
  
  s.source_files  = "Geometris", "Geometris/**/*.{h,m,swift}"
end

