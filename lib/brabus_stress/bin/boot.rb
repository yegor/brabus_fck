$BRABUS_STRESS_ROOT = File.expand_path("..", File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
Bundler.require(:default) if defined?(Bundler)
require 'active_support/core_ext'
require 'active_support/dependencies'

ActiveSupport::Dependencies.autoload_paths << File.expand_path('lib', $BRABUS_STRESS_ROOT)