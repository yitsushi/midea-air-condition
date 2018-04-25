# frozen_string_literal: true

require_relative 'client'
require_relative 'device'
require_relative 'packet_builder'
require_relative 'security'
require_relative 'version'

# MideaAirCondition namespace
module MideaAirCondition
  # Module to deparate command classes
  module Command
  end
end

path = File.join(File.dirname(__FILE__), 'commands', 'command.rb')
require path
path = File.join(File.dirname(__FILE__), 'commands', '*.rb')
Dir.glob(path).each do |file|
  require file
end
