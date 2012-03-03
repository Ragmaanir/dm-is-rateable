# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "dm-is-rateable"
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Martin Gamsjaeger (snusnu)", "Ragmaanir"]
  s.date = "2012-03-03"
  s.description = "DataMapper plugin that adds the possibility to rate models"
  s.email = "ragmaanir@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.markdown",
    "TODO"
  ]
  s.files = [
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "History.txt",
    "LICENSE",
    "Manifest.txt",
    "README.markdown",
    "Rakefile",
    "TODO",
    "VERSION",
    "dm-is-rateable.gemspec",
    "lib/dm-is-rateable.rb",
    "lib/dm-is-rateable/is/rateable.rb",
    "lib/dm-is-rateable/is/version.rb",
    "spec/integration/is_multi_rateable_spec.rb",
    "spec/integration/is_rateable_by_as_spec.rb",
    "spec/integration/is_rateable_by_concerning_spec.rb",
    "spec/integration/is_rateable_by_spec.rb",
    "spec/integration/is_rateable_by_with_spec.rb",
    "spec/integration/rateable_spec.rb",
    "spec/spec_helper.rb",
    "tasks/hoe.rb"
  ]
  s.homepage = "http://github.com/Ragmaanir/dm-is-rateable"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Rating plugin for datamapper"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<dm-validations>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<dm-aggregates>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<dm-timestamps>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<dm-types>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<dm-is-remixable>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<dm-migrations>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.1.1"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<dm-core>, ["~> 1.2.0"])
      s.add_dependency(%q<dm-validations>, ["~> 1.2.0"])
      s.add_dependency(%q<dm-aggregates>, ["~> 1.2.0"])
      s.add_dependency(%q<dm-timestamps>, ["~> 1.2.0"])
      s.add_dependency(%q<dm-types>, ["~> 1.2.0"])
      s.add_dependency(%q<dm-is-remixable>, ["~> 1.2.0"])
      s.add_dependency(%q<dm-migrations>, ["~> 1.2.0"])
      s.add_dependency(%q<i18n>, [">= 0"])
      s.add_dependency(%q<activesupport>, ["~> 3.1.1"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<dm-core>, ["~> 1.2.0"])
    s.add_dependency(%q<dm-validations>, ["~> 1.2.0"])
    s.add_dependency(%q<dm-aggregates>, ["~> 1.2.0"])
    s.add_dependency(%q<dm-timestamps>, ["~> 1.2.0"])
    s.add_dependency(%q<dm-types>, ["~> 1.2.0"])
    s.add_dependency(%q<dm-is-remixable>, ["~> 1.2.0"])
    s.add_dependency(%q<dm-migrations>, ["~> 1.2.0"])
    s.add_dependency(%q<i18n>, [">= 0"])
    s.add_dependency(%q<activesupport>, ["~> 3.1.1"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end

