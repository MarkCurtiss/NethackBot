require 'rake'
require 'rake/testtask'

task :default => [:run]

Rake::TestTask.new do |t|
  t.libs << 'test' << 'lib' << 'bin'
  t.test_files = FileList['test/test*.rb'].exclude('test_run.rb')
  t.verbose = true
end

namespace :test do
  desc 'Run a sanity check - this attempts to post to a dummy nethack account to see if your environment is setup properly'
  task "sanity" do 
    ruby "-I lib:bin test/test_run.rb"
    #really, this should cleanup the logs/ and games/ directory that the tests create.
    #unfortunately, these will wind up mixed in with the actual logs and games, so it's not safe to delete.
    #FileUtils.remove_dir('logs')
    #FileUtils.remove_dir('games')
  end
end

desc 'Runs the nethack bot [default]'
task :run do |t|
  ruby '-I lib bin/nethack_bot.rb'
end
