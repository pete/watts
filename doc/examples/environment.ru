# This example gives you a feel for the environment in which Watts::Resources
# run.  By "environment", of course, I really just mean that the 'env' value
# Rack gives you on requests is accessible from inside your resources.  You can
# request /, /foo, or whatever.  If you want to have a look at how query string
# parsing works, try having a look at /query?asdf=jkl%3B .  This example just
# uses the CGI library that comes with Ruby for parsing queries.

require 'watts'
require 'pp'
require 'cgi'

class WattsEnvironment < Watts::App
	class EnvPrinter < Watts::Resource
		get { |*a|
			s = ''
			PP.pp env, s
			s
		}
	end

	class Queries < Watts::Resource
		get {
			CGI.parse(env['QUERY_STRING']).inspect rescue 'Couldn\'t parse.'
		}
	end

	res('/', EnvPrinter) {
		res('foo', EnvPrinter)
		res([:yeah], EnvPrinter)
		res('query', Queries)
	}
end

app = WattsEnvironment.new
builder = Rack::Builder.new { run app }
run builder
