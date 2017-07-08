require 'test/unit'
require 'watts'

class RouteTest < Test::Unit::TestCase
	def test_matching
		r = Hash.new { |h,k|
			h[k] = Class.new(Watts::Resource) {
				%i(name inspect to_s).each { |m|
					define_singleton_method(m) { "TestResource#{k}" }
				}
			}
		}

		app = Class.new(Watts::App) {
			res('/', r[1]) {
				res(['one', :two], r[2]) {
					res(/three/, r[3]) { resource('4', r[4]) }
					res(:five, r[5])
				}
			}
		}.new

		# We expect for match to return [resource, args] or nil.
		assert_equal [r[1], []], app.match('/')
		assert_nil app.match('/one')
		assert_nil app.match('/one/')
		assert_equal [r[2], ['two']], app.match('/one/two')
		assert_equal [r[3], ['two', 'three']], app.match('/one/two/three')
		assert_equal [r[4], ['two', 'three']], app.match('/one/two/three/4')
		assert_nil app.match('/one/two/three/four')
		assert_nil app.match('Just some random gibberish.  Bad client!')

		# Next, we check to make sure that we can generate a path to the
		# resources.
		assert_equal '/', app.path_to(r[1])
		assert_equal '/one/asdf', app.path_to(r[2], 'asdf')
		assert_equal '/one/2/three', app.path_to(r[3], '2', 'three')
		assert_equal '/one/2/3three3', app.path_to(r[3], '2', '3three3')
		assert_equal '/one/2/3three/4', app.path_to(r[4], '2', '3three')

		assert_equal nil, app.path_to(r[3])
		assert_equal nil, app.path_to(r[3], '2', '3')
	end
end
