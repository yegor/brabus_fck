$BRABUS_STRESS_ROOT = File.expand_path("..", File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
Bundler.require(:default) if defined?(Bundler)
require 'active_support/core_ext'
require 'active_support/dependencies'
# require "em-synchrony"
# require "em-synchrony/fiber_iterator"

# ActiveSupport::Dependencies.autoload_paths << File.expand_path('lib', $BRABUS_STRESS_ROOT)

# Fucking ruby threading
#
Dir.glob(File.expand_path('lib/brabus_stress/sync.rb', $BRABUS_STRESS_ROOT)) {|file| require file}

Dir.glob(File.expand_path('lib/*.rb', $BRABUS_STRESS_ROOT)) {|file| require file}

Dir.glob(File.expand_path('lib/brabus_stress/steps/*.rb', $BRABUS_STRESS_ROOT)) {|file| require file}
Dir.glob(File.expand_path('lib/brabus_stress/scenarios/*.rb', $BRABUS_STRESS_ROOT)) {|file| require file}
Dir.glob(File.expand_path('lib/brabus_stress/cpacket/*.rb', $BRABUS_STRESS_ROOT)) {|file| require file}

Dir.glob(File.expand_path('lib/brabus_stress/*.rb', $BRABUS_STRESS_ROOT)) {|file| require file}
