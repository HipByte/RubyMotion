require 'bacon'
require 'mocha'
require 'mocha-on-bacon'

$:.unshift File.expand_path('../../../lib', __FILE__)

Mocha::Configuration.prevent(:stubbing_non_existent_method)
