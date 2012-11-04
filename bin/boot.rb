$BRABUS_FCK_ROOT = File.expand_path("..", File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
Bundler.require(:default) if defined?(Bundler)

require 'active_support/core_ext'
require 'active_support/dependencies'

require File.expand_path("lib/brabus_fck",  $BRABUS_FCK_ROOT)
BrabusFck.app_root = $BRABUS_FCK_ROOT

ActiveSupport::Dependencies.autoload_paths <<  File.expand_path('lib', $BRABUS_FCK_ROOT)