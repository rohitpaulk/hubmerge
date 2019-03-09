lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hubmerge/version"

Gem::Specification.new do |spec|
  spec.name          = "hubmerge"
  spec.version       = Hubmerge::VERSION
  spec.authors       = ["Paul Kuruvilla"]
  spec.email         = ["rohitpaulk@gmail.com"]

  spec.summary       = "Merge GitHub PRs in bulk!"
  spec.description   = "A gem to merge multiple GitHub PRs that match a search query"
  spec.homepage      = "https://github.com/rohitpaulk/hubmerge"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency "octokit",  "~> 4.0"
  spec.add_dependency "tty-prompt", "~> 0.18"
  spec.add_dependency "tty-spinner", "~> 0.19"
end
