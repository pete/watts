# This is the place to stuff all of the monkey-patches.

require 'metaid'

class Class
	# Has instances delegate methods to the class.
	def to_instance *ms
		ms.each { |m|
			define_method(m) { |*a|
				self.class.send(m, *a)
			}
		}
	end

	# A replacement for def x; @x ||= Y.new; end
	def attr_new klass, *attrs
		attrs.each { |attr|
			ivname = "@#{attr}"
			define_method(attr) {
				ivval = instance_variable_get(ivname)
				return ivval if ivval
				instance_variable_set(ivname, klass.new)
			}
		}
	end
end
