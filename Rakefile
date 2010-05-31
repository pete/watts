require 'rake/gempackagetask'
require 'rake/rdoctask'

$: << "#{File.dirname(__FILE__)}/lib"

spec = Gem::Specification.new { |s|
	s.platform = Gem::Platform::RUBY

	s.author = "Pete Elmore"
	s.email = "pete@debu.gs"
	s.files = Dir["{lib,doc,bin,ext}/**/*"].delete_if {|f| 
		/\/rdoc(\/|$)/i.match f
	} + %w(Rakefile)
	s.require_path = 'lib'
	s.has_rdoc = true
	s.extra_rdoc_files = Dir['doc/*'].select(&File.method(:file?))
	s.extensions << 'ext/extconf.rb' if File.exist? 'ext/extconf.rb'
	Dir['bin/*'].map(&File.method(:basename)).map(&s.executables.method(:<<))

	s.name = 'watts'
	s.summary =
		"Another Rack-based web framework.  Yes, another one.  Sorry, guys."
	s.homepage = "http://debu.gs/#{s.name}"
	%w().each &s.method(:add_dependency)
	s.version = '0.0.1'
}

Rake::RDocTask.new(:doc) { |t|
	t.main = 'doc/README'
	t.rdoc_files.include 'lib/**/*.rb', 'doc/*', 'bin/*', 'ext/**/*.c', 
		'ext/**/*.rb'
	t.options << '-S' << '-N'
	t.rdoc_dir = 'doc/rdoc'
}

Rake::GemPackageTask.new(spec) { |pkg|
	pkg.need_tar_bz2 = true
}
desc "Cleans out the packaged files."
task(:clean) {
	FileUtils.rm_rf 'pkg'
}

desc "Builds and installs the gem for #{spec.name}"
task(:install => :package) { 
	g = "pkg/#{spec.name}-#{spec.version}.gem"
	system "sudo gem install -l #{g}"
}

desc "Runs IRB, automatically require()ing #{spec.name}."
task(:irb) {
	exec "irb -Ilib -r#{spec.name}"
}
