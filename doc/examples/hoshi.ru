#!/usr/bin/env rackup
# An example illustrating how to use the for_html_view method, with help from
# Hoshi.  Try running this and opening http://localhost:8080/ in a browser.

require 'watts'
require 'hoshi'

class HelloHTML < Watts::App
	# First, a simple, traditional greeting, done in Hoshi:
	class View < Hoshi::View :html5
		def hello
			doc {
				head { title 'Hello, World!' }
				body {
					h1 'Here is your greeting:'
					p 'Hello, World!'
				}
			}
			render
		end
	end

	Res = Watts::Resource.for_html_view(View, :hello)

	res('/', Res)
end

app = HelloHTML.new
builder = Rack::Builder.new { run app }
run builder
