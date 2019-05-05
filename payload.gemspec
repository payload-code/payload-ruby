lib = File.join(File.dirname(__FILE__), "lib")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'payload/version'

Gem::Specification.new do |spec|
  spec.name = "payload-api"
  spec.version = Payload::VERSION
  spec.required_ruby_version = ">= 2.0.0"
  spec.summary = "Payload ruby library"
  spec.description = "A simple library to interface with the Payload API. See https://docs.payload.co for details."
  spec.author = "Payload"
  spec.email = "help@payload.co"
  spec.homepage = "https://docs.payload.co"
  spec.license = "MIT"

  spec.files = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- test/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
