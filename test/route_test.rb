require 'test/unit'
require 'watts'

class RouteTest < Test::Unit::TestCase
	def test_matching
		r1 = Class.new(Watts::Resource)
		r2 = Class.new(Watts::Resource)
		r3 = Class.new(Watts::Resource)
		r4 = Class.new(Watts::Resource)

		app = Class.new(Watts::App) {
			resource('/', r1) {
				resource(['one', :two], r2) {
					resource(/three/, r3) { resource('4', r4) }
				}
			}
		}.new

		# We expect for match to return [resource, args] or nil.
		assert_equal [r1, []], app.match('/')
		assert_nil app.match('/one')
		assert_nil app.match('/one/')
		assert_equal [r2, ['two']], app.match('/one/two')
		assert_equal [r3, ['two', 'three']], app.match('/one/two/three')
		assert_equal [r4, ['two', 'three']], app.match('/one/two/three/4')
		assert_nil app.match('/one/two/three/four')
		assert_nil app.match('Just some random gibberish.  Bad client!')

		# Next, we check to make sure that we can generate a path to the
		# resources.
		assert_equal '/', app.path_to(r1)
		assert_equal '/one/asdf', app.path_to(r2, 'asdf')
		assert_equal '/one/2/three', app.path_to(r3, '2', 'three')
		assert_equal '/one/2/3three3', app.path_to(r3, '2', '3three3')
		assert_equal '/one/2/3three/4', app.path_to(r4, '2', '3three')
		assert_equal nil, app.path_to(r3, '2', '3')
	end
end
