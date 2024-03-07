# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'csv_decision'
  spec.version       = '0.5.1'
  spec.authors       = ['Brett Vickers']
  spec.email         = ['brett@phillips-vickers.com']
  spec.description   = 'CSV based Ruby decision tables.'
  spec.summary       = <<-DESC
    CSV Decision implements CSV based Ruby decision tables. It parses and loads
    decision table files which can then be used to execute complex conditional
    logic against an input hash, producing a decision as an output hash.
    DESC
  spec.homepage      = 'https://github.com/bpvickers/csv_decision.git'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_dependency 'activesupport', '~> 7.0'

  spec.add_development_dependency 'benchmark-ips',         '~> 2.7'
  spec.add_development_dependency 'benchmark-memory',      '~> 0.1'
  spec.add_development_dependency 'bundler',               '~> 2.1'
  spec.add_development_dependency 'oj',                    '~> 3.3'
  spec.add_development_dependency 'rake',                  '~> 12.3'
  spec.add_development_dependency 'rspec',                 '~> 3.7'
  spec.add_development_dependency 'rubocop',               '~> 0.52'
  spec.add_development_dependency 'rufus-decision',        '~> 1.3'
  spec.add_development_dependency 'simplecov',             '~> 0.15'
end
