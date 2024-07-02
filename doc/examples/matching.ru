#!/usr/bin/env ruby
# An illustration of the pattern-matching capabilities of Watts.  Some URLs to
# try if you start this one up:
# 	http://localhost:8080/strlen/foo (Which should tell you '3'.)
# 	http://localhost:8080/fib/15 (Which should give you 987.)
# 	http://localhost:8080/fib/foo (Which is a 404.  'foo' isn't a number!)
# 	http://localhost:8080/fib/f (Which should give you 0x3db.)
# 	http://localhost:8080/fib/0x15 (Which should give you 0x452f.)

require 'watts'

class MatchingDemo < Watts::App
	class Strlen < Watts::Resource
		# Takes an argument, and just returns the length of the argument.
		get { |str| str.length.to_s + "\n" }
	end

	class Fibonacci < Watts::Resource
		# This resource takes an argument for GET.  It is filled in by Watts
		# according to the argument pattern passed into resource below.
		get { |n| fib(n.to_i).to_s + "\n" }

		# A naive, recursive, slow, text-book implementation of Fibonacci.
		def fib(n)
			if n < 2
				1
			else
				fib(n - 1) + fib(n - 2)
			end
		end
	end

	# As above, but with a base-16 number.
	class HexFibonacci < Fibonacci
		get { |n| "0x" + fib(n.to_i(16)).to_s(16) + "\n" }
	end

	res('/') {
		# A symbol can be used to indicate an 'argument' component of a path,
		# which is in turn passed to the resource's method as paths.  It will
		# match anything, making it almost equivalent to just using an empty
		# regex (see below), except that it can serve as documentation.
		res(['strlen', :str], Strlen)

		res('fib') {
			# You can match arguments based on a regex.  The path component for
			# the regex is passed to the resource's method as part of the
			# argument list.
			res([/^[0-9]+$/], Fibonacci)

			# As above, but here we use hexadecimal.  If the pattern for
			# Fibonacci doesn't match, then we'll end up hitting this one.
			res([/^(0x)?[0-9a-f]+$/i], HexFibonacci)
		}
	}
end

app = MatchingDemo.new
builder = Rack::Builder.new { run app }
run builder
