
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "code_quality/version"

Gem::Specification.new do |spec|
  spec.name          = "code_quality"
  spec.version       = CodeQuality::VERSION
  spec.authors       = ["RainChen"]
  spec.email         = ["hirainchen@gmail.com"]

  spec.summary       = %q{run code quality and security audit report with one rake task}
  spec.description   = %q{run code quality and security audit report with one rake task}
  spec.homepage      = "https://github.com/rainchen/code_quality"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|doc)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler-audit"
  spec.add_dependency "brakeman"
  spec.add_dependency "rubycritic", "~> 3.3.0"
  spec.add_dependency "rubocop", "~> 0.52.0"
  spec.add_dependency "rubocop-github", "~> 0.8.1"
  spec.add_dependency "code_metric_fu", "~> 4.14.3"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
