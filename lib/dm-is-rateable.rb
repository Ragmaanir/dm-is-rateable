require 'pathname'

require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-is-remixable'
require 'dm-migrations'

require 'active_support/core_ext/class'
require 'active_support/inflector'

# Require plugin-files
#require Pathname(__FILE__).dirname.expand_path / 'dm-is-rateable' / 'is' / 'rateable.rb'
require File.join('dm-is-rateable','is','rateable.rb')

# Include the plugin in Resource
DataMapper::Model.append_extensions DataMapper::Is::Rateable
