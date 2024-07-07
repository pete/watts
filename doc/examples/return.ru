#!/usr/bin/env rackup
# Demonstrating the return values Watts expects from methods.  Some URLs to
# try if you start this one up:
# 	http://localhost:9292/string
# 	http://localhost:9292/array
# 	http://localhost:9292/nil
# 	http://localhost:9292/response

require 'watts'
require 'hoshi'

class ReturnDemo < Watts::App
	SomeHTML = Hoshi::View(:html5) {
		doc
		html{body{h1 'Hello, World!';p 'This is some HTML.'}}
	}

	class RString < Watts::Resource
		get { "Returned a string, so it's text/plain." }
	end

	class RArray < Watts::Resource
		get { [200, {'content-type' => 'text/html'}, [SomeHTML]] }
	end

	class RNil < Watts::Resource
		get {
			response.body << SomeHTML
			response.headers.merge!({
				'content-type' => 'text/html; charset=utf-8',
				'content-length' => SomeHTML.bytesize.to_s,
			})
			nil
		}
	end

	class RResponse < Watts::Resource
		get {
			Rack::Response.new.tap { |r|
				r.body << SomeHTML
				r.headers['content-type'] = 'text/html'
			}
		}
	end

	res 'string', RString
	res 'array', RArray
	res 'nil', RNil
	res 'response', RResponse
end

run ReturnDemo.new
