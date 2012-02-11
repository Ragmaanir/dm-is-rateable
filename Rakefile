begin
  # Just in case the bundle was locked
  # This shouldn't happen in a dev environment but lets be safe
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end

Bundler.require(:default, :development)


begin

  require 'rake'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|

    gem.name        = 'dm-is-rateable'
    gem.summary     = 'Rating plugin for datamapper'
    gem.description = 'DataMapper plugin that adds the possibility to rate models'
    gem.email       = 'gamsnjaga@gmail.com'
    gem.homepage    = 'http://github.com/snusnu/dm-is-rateable'
    gem.authors     = [ 'Martin Gamsjaeger (snusnu)' ]

    #gem.add_dependency 'dm-core',           '~> 0.10.2'
    #gem.add_dependency 'dm-validations',    '~> 0.10.2'
    #gem.add_dependency 'dm-aggregates',     '~> 0.10.2'
    #gem.add_dependency 'dm-timestamps',     '~> 0.10.2'
    #gem.add_dependency 'dm-types',          '~> 0.10.2'
    #gem.add_dependency 'dm-is-remixable',   '~> 0.10.2'


    DM_VERSION = '~> 1.2.0'

    gem.add_dependency 'dm-core', DM_VERSION

    gem.add_dependency 'dm-validations',  DM_VERSION
    gem.add_dependency 'dm-aggregates',   DM_VERSION
    gem.add_dependency 'dm-timestamps',   DM_VERSION
    gem.add_dependency 'dm-types',        DM_VERSION
    gem.add_dependency 'dm-is-remixable', DM_VERSION
    gem.add_dependency 'dm-migrations',   DM_VERSION

    gem.add_dependency 'activesupport', '~> 3.1.1'

    gem.add_development_dependency 'rspec', '~> 2.8'
    gem.add_development_dependency 'yard',  '~> 0.5'

  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }

rescue LoadError => e
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
  puts e.message
  puts e.backtrace
end
