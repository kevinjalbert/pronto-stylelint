# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'pronto/stylelint/version'

Gem::Specification.new do |s|
  s.name = 'pronto-stylelint'
  s.version = Pronto::StylelintVersion::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Kevin Jalbert']
  s.email = 'kevin.j.jalbert@gmail.com'
  s.homepage = 'https://github.com/kevinjalbert/pronto-stylelint'
  s.summary = <<-SUMMARY
    Pronto runner for stylelint, the mighty, modern CSS linter.
  SUMMARY

  s.licenses = ['MIT']
  s.required_ruby_version = '>= 2.3.0'

  s.files = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.require_paths = ['lib']
  s.requirements << 'stylelint (in PATH)'

  s.add_dependency('pronto', '>= 0.10', '< 0.12')
  s.add_dependency('rugged', '>= 0.24', '< 2.0')
end
