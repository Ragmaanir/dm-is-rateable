# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler'

#require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov)

task :default => :spec

Jeweler::Tasks.new do |gem|
  gem.name        = 'dm-is-rateable'
  gem.summary     = 'Rating plugin for datamapper'
  gem.description = 'DataMapper plugin that adds the possibility to rate models'
  gem.email       = 'ragmaanir@gmail.com'
  gem.homepage    = 'http://github.com/Ragmaanir/dm-is-rateable'
  gem.authors     = [ 'Martin Gamsjaeger (snusnu)', 'Ragmaanir' ]
end

Jeweler::RubygemsDotOrgTasks.new
#Jeweler::GemcutterTasks.new

require 'yard'
YARD::Rake::YardocTask.new

FileList['tasks/**/*.rake'].each { |task| import task }
