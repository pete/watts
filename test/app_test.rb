require 'test/unit'
require 'watts'

class AppTest < Test::Unit::TestCase
	def test_responses
		%w(str resp arr).each { |path|
			resp = mkreq "/#{path}"
			assert_equal 200, resp.status,
				"Expect 200 OK from /#{path}"
			assert_equal 'test', resp.body,
				"Expect the appropriate body from /#{path}"
		}
	end

	def test_bad_methods
		resp = mkreq "/str", 'DOODLE'
		assert_equal 501, resp.status,
			"Expect that responses to bad methods comply with RFC2616."
	end

	def test_404
		resp = mkreq "/notfound"
		assert_equal 404, resp.status,
			"Expect to not find /notfound."
	end

	def test_request
		resp = mkreq '/method'
		assert_equal 'GET', resp.body,
			"Expected the request method in the body."
	end

	def test_resource_args
		# This behavior may or may not be desirable.  It is unfortunate that the
		# pattern-matching and the arity of the methods can't line up completely.
		assert_raise_kind_of(ArgumentError) {
			resp = mkreq "/arity/mismatch"
		}
	end

	def app
		@app ||= begin
			gr = method(:getres) # Scoping!
			app = Class.new(Watts::App) {
				res('str', gr.call { 'test' })
				res('resp', gr.call { response.body << 'test';nil })
				res('arr', gr.call { [200, {}, ['test']] })

				res(['arity', :mismatch], gr.call { || 'test' })
				res('method', gr.call { request.env['REQUEST_METHOD'] })
			}.new
		end
	end

	def getres &b
		Class.new(Watts::Resource) {
			get &b
		}
	end

	def mkreq path, m = 'GET'
		req = Rack::MockRequest.new app
		req.request(m, path)
	end
end
