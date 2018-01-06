require 'test/unit'
require 'watts'

class MethodsTest < Test::Unit::TestCase
	def test_auto_head
		r = Class.new(Watts::Resource)
		env = {}

		r.get { |arg| [9001, {'no' => arg}, ["LENGTHY"]] }
		getresp = r.new(env).get(:asdf)
		headresp = r.new(env).head

		assert_equal 9001, getresp[0]
		assert_equal 405, headresp[0]

		r.auto_head
		autoheadresp = r.new(env).head(:asdf)
		assert_equal getresp[0..1], autoheadresp[0..1]
		assert_equal [], autoheadresp[2]
	end

	def test_accept
		r = Class.new(Watts::Resource)
		r.get { }
		resp = r.new({}).options
		assert resp[1]['Allow'], "Should have an Allow: header."
		assert_equal %w(GET), resp[1]['Allow'].split(/, */).sort,
			"Should allow only GET."
		rs = Class.new(r)
		r.get { }
		r.auto_head
		resp = r.new({}).options
		assert resp[1]['Allow'], "Should have an Allow: header."
		assert_equal %w(GET HEAD), resp[1]['Allow'].split(/, */).sort,
			"Should allow GET and HEAD."
		resp = r.new({}).post
		assert_equal 405, resp[0],
			"Should give us 'Method not allowed'."
		assert resp[1]['Allow'], "Should have an Allow: header."
		assert_equal %w(GET HEAD), resp[1]['Allow'].split(/, */).sort,
			"Should specify that only GET and HEAD are allowed."

		rp = Class.new(r)
		resp = r.new({}).options
		respp = r.new({}).options
		assert_equal resp, respp,
			"Subclasses should inherit Allow: values."
	end
end
