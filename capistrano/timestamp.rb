unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance.load do

  namespace :deploy do
    namespace :timestamp do
      desc "Copies the timestamp template to the public directory."
      task :create, :except => { :no_release => true } do
        template = File.read("config/deploy/deploy_time.html.erb")
        put ERB.new(template).result(binding), "#{shared_path}/config/deploy_time.html"
      end

      desc "Updates the symlinks for timestamp to the just deployed release."
      task :symlink do
        run "ln -nfs #{shared_path}/config/deploy_time.html #{release_path}/public/deploy_time.html"
      end
    end

    after "deploy:finalize_update", "deploy:timestamp:create"
    after "deploy:finalize_update", "deploy:timestamp:symlink"
  end

end
