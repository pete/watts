#!/usr/bin/env ruby
# This example gives you a feel for the environment in which Watts::Resources
# run.  By "environment", of course, I really just mean that the 'env' value
# Rack gives you on requests is accessible from inside your resources.

require 'watts'
require 'pp'

class WattsEnvironment < Watts::App
	class EnvPrinter < Watts::Resource
		get { |*a|
			s = ''
			PP.pp env, s
			s
		}
	end

	resource('/', EnvPrinter) {
		resource('foo', EnvPrinter)
		resource([:yeah], EnvPrinter)
	}
end

app = WattsEnvironment.new
builder = Rack::Builder.new { run app }

Rack::Handler::Mongrel.run builder, :Port => 8080
