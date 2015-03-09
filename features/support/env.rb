require 'cucumber'
require 'json'
require 'minitest/spec'
require 'minitest/autorun'
require_relative '../../PageObject/page_objects.rb'

$USERNAME = ENV['AMAZON_USERNAME']
$PASSWORD = ENV['AMAZON_PASSWORD']
