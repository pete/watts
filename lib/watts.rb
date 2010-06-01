%w(
	forwardable
	metaid
	rack
	watts/monkey_patching
).each &method(:require)

# Here's the main module, Watts.
module Watts
	# You are unlikely to need to interact with this.  It's mainly for covering
	# up the path-matching logic for Resources.
	class Path
		extend Forwardable
		include Enumerable

		attr_accessor :resource
		attr_new Hash, :sub_paths

		def match path, args
			if path.empty?
				[resource, args]
			elsif(sub = self[path[0]])
				sub.match(path[1..-1], args)
			else
				each { |k,sub|
					if k.kind_of?(Regexp) && k.match(path[0])
						return sub.match(path[1..-1], args + [path[0]])
					end
				}
				each { |k,sub|
					if k.kind_of?(Symbol)
						return sub.match(path[1..-1], args + [path[0]])
					end
				}
				nil
			end
		end

		def_delegators :sub_paths, :'[]', :'[]=', :each
	end

	# In order to have a Watts app, you'll want to subclass Watts::App.  For a
	# good time, you'll also probably want to provide some resources to that
	# class using the resource method, which maps paths to resources.
	class App
		Errors = {
			400 =>
				[400, {'Content-Type' => 'text/plain'}, "400 Bad Request.\n"],
			404 =>
				[404, {'Content-Type' => 'text/plain'}, "404 Not Found\n"],
		}

		class << self
			attr_new Hash, :http_methods
			attr_new Watts::Path, :path_map
			attr_new Array, :path_stack
			attr_writer :path_stack
		end

		def self.decypher_path p
			return p if p.kind_of?(Array)
			return [] if ['/', ''].include?(p)
			p = p.split('/')
			p.select { |sub| sub != '' }
		end

		to_instance :path_map, :decypher_path

		# If you want your Watts application to do anything at all, you're very
		# likely to want to call this method at least once.  The basic purpose
		# of the method is to tell your app how to match a resource to a path.
		# For example, if you create a resource (see Watts::Resource) Foo, and
		# you want requests against '/foo' to match it, you could do this:
		# 	resource('foo', Foo)
		#
		# The first argument is the path, and the second is the resource that
		# path is to match.  (Please see the README for more detailed
		# documentation of path-matching.)  You may also pass it a block, in
		# which resources that are defined are 'namespaced'.  For example, if
		# you also had a resource called Bar and wanted its path to be a
		# sub-path of the Foo resource's (e.g., '/foo/bar'), then typing these
		# lines is a pretty good plan:
		# 	resource('foo', Foo) {
		# 		resource('bar', Bar)
		# 	}
		#
		# Lastly, the resource argument itself is optional, for when you want a
		# set of resources to be namespaced under a given path, but don't
		# have a resource in mind.  For example, if you suddenly needed your
		# entire application to reside under '/api', you could do this:
		# 	resource('api') {
		#	 	resource('foo', Foo) {
		# 			resource('bar', Bar)
		#			resource('baz', Baz)
		# 		}
		#	}
		#
		# This is probably the most important method in Watts.  Have a look at
		# the README and the example applications under doc/examples if you
		# want to understand the pattern-matching, arguments to resources, etc.
		def self.resource(path, res = nil, &b)
			path = decypher_path(path)

			last = (path_stack + path).inject(path_map) { |m,p|
				m[p] ||= Path.new
			}
			last.resource = res

			if b
				old_stack = path_stack
				self.path_stack = old_stack + path
				b.call
				self.path_stack = old_stack
			end
			res
		end

		# Given a path, returns the matching resource, if any.
		def match req_path
			req_path = decypher_path req_path
			path_map.match req_path, []
		end

		# Our interaction with Rack.
		def call env, req_path = nil
			rm = env['REQUEST_METHOD'].downcase.to_sym
			return(Errors[400]) unless Resource::HTTPMethods.include?(rm)

			req_path ||= decypher_path env['REQUEST_PATH']
			resource_class, args = match req_path

			if resource_class
				res = resource_class.new(env)
				res.send(rm, *args)
			else
				Errors[404]
			end
		end
	end

	# HTTP is all about resources, and this class represents them.  You'll want
	# to subclass it and then define some HTTP methods on it, then use
	# your application's resource method to tell it where to find these
	# resources.  (See Watts::App.resource().)  If you want your resource to
	# respond to GET with a cheery, text/plain greeting, for example:
	# 	class Foo < Watts::Resource
	# 		get { || "Hello, world!" }
	# 	end
	# 
	# Or you could do something odd like this:
	# 	class RTime < Watts::Resource
	#		class << self; attr_accessor :last_post_time; end
	#
	# 		get { || "The last POST was #{last_post_time}." }
	# 		post { ||
	# 			self.class.last_post_time = Time.now.strftime('%F %R')
	#			[204, {}, []]
	#		}
	#
	#		def last_post_time
	#			self.class.last_post_time || "...never"
	#		end
	#	end
	# 
	# It is also possible to define methods in the usual way (e.g., 'def get
	# ...'), although you'll need to add them to the list of allowed methods
	# (for OPTIONS) manually.  Have a look at the README and doc/examples.
	class Resource
		HTTPMethods =
			[:get, :post, :put, :delete, :head, :options, :trace, :connect]

		class << self
			attr_new Array, :http_methods
		end

		# For each method allowed by HTTP, we define a "Method not allowed"
		# response, and a method for generating a method.  You may also just
		# def methods, as seen below for the options method.
		HTTPMethods.each { |http_method|
			meta_def(http_method) { |&b|
				http_methods << http_method.to_s.upcase
				define_method(http_method) { |*args|
					begin
						resp = b[*args]
					rescue ArgumentError => e
						# TODO:  Arity/path args mismatch handler here.
						raise e
					end

					# TODO:  Problems.
					case resp
					when nil
						[response.status, response.headers, response.body]
					when Array
						resp
					else
						[200, {'Content-Type' => 'text/plain'}, resp.to_s]
					end
				}
			}
			define_method(http_method) { |*args| default_http_method(*args) }
		}

		# This method is for creating Resources that simply wrap first-class
		# HTML views.  It was created with Hoshi in mind, although you can use
		# any class that can be instantiated and render some HTML when the
		# specified method is called.  It takes two arguments:  the view class,
		# and the method to call to render the HTML.
		def self.for_html_view klass, method
			c = Class.new HTMLViewResource
			c.view_class = klass
			c.view_method = method
			c
		end

		to_instance :http_methods
		attr_new Rack::Response, :response
		attr_accessor :env, :response

		# Every resource, on being instantiated, is given the Rack env.
		def initialize(env)
			self.env = env
			self.response = Rack::Response.new
		end

		# The default options method, to comply with RFC 2616, returns a list
		# of allowed methods in the Allow header.  These are filled in when the
		# method-defining methods (i.e., get() et al) are called.
		def options(*args)
			[
				200,
				{
					'Content-Length' => '0', # cf. RFC 2616
					'Allow' => http_methods.join(', ')
				},
				[]
			]
		end

		# By default, we return "405 Method Not Allowed" and set the Allow:
		# header appropriately.
		def default_http_method(*args)
			[405, { 'Allow' => http_methods.join(', ') }, 'Method not allowed.']
		end
	end

	# See the documentation for Watts::Resource.for_html_view().
	class HTMLViewResource < Resource
		class << self
			attr_writer :view_class, :view_method
		end

		def self.view_class
			@view_class ||= (superclass.view_class rescue nil)
		end

		def self.view_method
			@view_method ||= (superclass.view_method rescue nil)
		end

		to_instance :view_class, :view_method

		def get *args
			[200, {'Content-Type' => 'text/html'},
				view_class.new.send(view_method, *args)]
		end
	end
end
