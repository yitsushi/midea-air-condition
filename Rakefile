# frozen_string_literal: true

require 'rubygems/package_task'
require 'rubygems/dependency_installer'
require 'rdoc/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

namespace :gem do
  specfile = 'midea-air-condition.gemspec'

  Gem::PackageTask.new(Gem::Specification.load(specfile)) {}

  desc 'Install this gem locally'
  task :install, [:user_install] => :gem do |_, args|
    args.with_defaults(user_install: false)
    Gem::Installer.new(
      "pkg/midea-air-condition-#{MideaAirCondition::VERSION}.gem",
      user_install: args.user_install
    ).install
  end
end

namespace :dependencies do
  desc 'Install development dependencies'
  task :install do |_|
    installer = Gem::Installer.new('')
    gemspec = Gem::Specification.load(specfile)
    unsatisfied_dep = gemspec.development_dependencies.reject do |dp|
      installer.installation_satisfies_dependency?(dp)
    end
    next if unsatisfied_dep.empty?
    unsatisfied_dep.each do |dp|
      Gem::DependencyInstaller.new(
        user_install: ENV['RUBY_ENV'] == 'citest'
      ).install(dp)
    end
  end
end

namespace :doc do
  desc 'generate API documentation'
  Rake::RDocTask.new do |rd|
    rd.rdoc_dir = 'doc'
    rd.main = 'README.md'
    rd.rdoc_files.include(
      'README.md',
      'LICENSE',
      "lib/**/*\.rb"
    )
    rd.options << '--line-numbers'
    rd.options << '--all'
  end
end

namespace :test do
  RuboCop::RakeTask.new(:rubocop)
  RSpec::Core::RakeTask.new(:spec)
end

task default: ['test:rubocop', 'test:spec']
