ENV['RACK_ENV'] = 'test'
require_relative '../web'
require 'rspec'
require 'capybara/rspec'
require 'capybara-webkit'

Capybara.app = PeakPortrait
Capybara.javascript_driver = :webkit