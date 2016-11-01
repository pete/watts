require 'test/unit'
require 'watts'

class AppTest < Test::Unit::TestCase
	def test_responses
		%w(str resp arr).each { |path|
			resp = mkreq "/#{path}"
			assert_equal 200, resp.status,
				"Expect 200 OK from /#{path}"
			# This test would have been that shorter, but Rack::MockResponse
			# gives a string, where Rack::Response gives an Enumerable.  Ouch.
			body = resp.body.kind_of?(String) ? resp.body : resp.body.join
			assert_equal 'test', body,
				"Expect the appropriate body from /#{path}"
		}
	end

	def test_bad_methods
		resp = mkreq "/str", 'DOODLE'
		assert_equal 501, resp.status,
			"Expect that responses to bad methods comply with RFC2616."
	end

	def app
		@app ||= begin
			gr = method(:getres) # Scoping!
			app = Class.new(Watts::App) {
				res('str', gr.call { 'test' })
				res('resp', gr.call { response.body << 'test';nil })
				res('arr', gr.call { [200, {}, ['test']] })
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
