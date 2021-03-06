
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
#$LOAD_PATH.unshift(File.dirname(__FILE__))

#require 'pathname'
#require Pathname(__FILE__).dirname.expand_path.parent + 'lib/dm-is-rateable'

require 'rspec'
require 'dm-is-rateable'

def load_driver(name, default_uri)
  return false if ENV['ADAPTER'] != name.to_s

  lib = "do_#{name}"

  begin
    gem lib, '>=0.9.5'
    require lib
    DataMapper.setup(name, ENV["#{name.to_s.upcase}_SPEC_URI"] || default_uri)
    DataMapper::Repository.adapters[:default] =  DataMapper::Repository.adapters[name]
    true
  rescue Gem::LoadError => e
    warn "Could not load #{lib}: #{e}"
    false
  end
end

ENV['ADAPTER'] ||= 'sqlite3'

HAS_SQLITE3  = load_driver(:sqlite3,  'sqlite3::memory:')
HAS_MYSQL    = load_driver(:mysql,    'mysql://localhost/dm_core_test')
HAS_POSTGRES = load_driver(:postgres, 'postgres://postgres@localhost/dm_core_test')

RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  c.fail_fast = true

  c.before(:suite) do
    unless HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
      fail 'need a database for testing (e.g. sqlite3)'
    end
  end
end

def unload_consts(*consts)
  consts.each do |c|
    c = "#{c}"
    Object.send(:remove_const, c) if Object.const_defined?(c)
  end
end



