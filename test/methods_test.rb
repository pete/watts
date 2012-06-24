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
		rs = Class.new(r)
		r.get { }
		resp = r.new({}).options
		$stderr.puts resp.inspect
	end
end
