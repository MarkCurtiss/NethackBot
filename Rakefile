require 'rake'
require 'rake/testtask'
require 'rake/clean'

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << 'test' << 'lib' << 'bin'
  t.test_files = FileList['test/test*.rb'].exclude('test/test_run.rb')
  t.verbose = true
end

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

