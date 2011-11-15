require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :test do
  desc 'Run a sanity check - this attempts to post to a dummy nethack account to see if your environment is setup properly'
  task "sanity" do 
    ruby("-I lib:bin:test test/test_run.rb")
  end
end

CLEAN.include(Rake::FileList['test/games', 'test/logs'])

desc 'Runs the nethack bot'
task :run do |t|
  ruby('-I lib bin/run')
end

