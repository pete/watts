#!/usr/bin/env ruby
# This is, I think, the simplest possible Watts application.  It starts up Rack
# on port 8080 and responds only to GET /.

require 'watts'

class Simple < Watts::App
	class EZResource < Watts::Resource
		get { "Hello, World!\n" }
	end

	resource('/', EZResource)
end

app = Simple.new
builder = Rack::Builder.new { run app }
run builder
