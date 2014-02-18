ENV['RACK_ENV'] = 'test'
require_relative '../web'
require 'rspec'
require 'capybara/rspec'

Capybara.app = PeakPortrait