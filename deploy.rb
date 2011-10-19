$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                               # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.9.2'                          # Or whatever env you want it to run in.
set :rvm_bin_path, '/usr/local/rvm/bin/'

require "bundler/capistrano"
require File.join(__FILE__, "..", "capistrano_config_yml")
require File.join(__FILE__, "..", "capistrano_timestamp")
require File.join(__FILE__, "..", "capistrano_hoptoad")
require File.join(__FILE__, "..", "capistrano_whenever")

set :application, "gatsby"

set :stages, %w[production staging qa]
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :skip_config_setup_on_shared, false # set this to true when deploying to multiple servers

default_run_options[:pty] = true                       # Must be set for the password prompt from git to work
set :repository, "git@github.com:obikosh/gatsby.git"   # Your clone URL
set :deploy_via, :remote_cache

set :ssh_options, { :forward_agent => true }
set :scm, "git"
set :git_enable_submodules, 1

set :keep_releases, 4

set :user, "obikosh"

set :use_sudo, true
set :copy_exclude, [".git/*", ".bundle/*", "log/*", ".rvmrc"]

set :new_relic_license_key, "2d7eaba12e4421a57186065f71eb05df06a630e1"

# runtime dependencies
depend :remote, :gem, "bundler", "~>1.0.10"

# tasks
namespace :deploy do
  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Seed the database"
  task :seed, :roles => :db do
    run_remote_rake('db:seed')
  end
end

namespace :bundler do
  task :install, :roles => :app, :except => { :no_release => true }  do
    run("gem install bundler --source=http://rubygems.org --version=1.0.18")
  end
end

after "deploy:setup", "bundler:install"
after "deploy", "deploy:cleanup"

# Rake helper task.
def run_remote_rake(rake_cmd)
  rake = fetch(:rake, "rake")
  rails_env = fetch(:rails_env, "production")
  migrate_env = fetch(:migrate_env, "")
  migrate_target = fetch(:migrate_target, :latest)

  directory = case migrate_target.to_sym
  when :current then
    current_path
  when :latest then
    current_release
  else
    raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
  end

  puts "#{migrate_target} => #{directory}"

  run "cd #{directory}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} #{rake_cmd.split(',').join(' ')}"
end
