%w(
	forwardable
	metaid
	rack
	watts/monkey_patching
).each &method(:require)

module Watts
	class Path
		extend Forwardable
		include Enumerable

		attr_accessor :resource
		attr_new Hash, :sub_paths

		def initialize
			@sub_paths = {}
		end

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

		def self.resource(path, res, &b)
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

		def match req_path
			req_path = decypher_path req_path
			path_map.match req_path, []
		end

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

	class Resource
		HTTPMethods = [:get, :post, :put, :delete, :head, :options]

		class << self
			attr_new Array, :http_methods
		end

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
						[200, {}, resp.to_s]
					end
				}
			}
			define_method(http_method) { |*args| default_http_method(*args) }
		}

		def self.for_html_view klass, method
			c = Class.new HTMLViewResource
			c.view_class = klass
			c.view_method = method
			c
		end

		attr_accessor :env, :response

		def initialize(env)
			self.env = env
			self.response = Rack::Response.new
		end

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

		to_instance :http_methods
		attr_new Rack::Response, :response

		# By default, we return "405 Method Not Allowed" and set the Allow:
		# header appropriately.
		def default_http_method(*args)
			[405, { 'Allow' => http_methods.join(', ') }, 'Method not allowed.']
		end
	end

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
