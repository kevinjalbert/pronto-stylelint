# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'rspec'
require 'pronto/stylelint'

Dir.glob("#{Dir.pwd}/spec/support/**/*.rb").sort.each { |file| require file }

RSpec.configure do |c|
  c.include RepositoryHelper
end
