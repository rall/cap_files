unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance.load do

  namespace :deploy do
    namespace :config do
      desc "create paths"
      task :setup, :except => { :no_release => true } do
        run "mkdir -p #{shared_path}/config"
      end

      desc <<-DESC
        Creates the configuration files from erb templates,

        This task expects templates following a naming convention of "config_type.yml.erb" \
        in the config/deploy/ directory

        When this recipe is loaded, db:other:create is automatically configured \
        to be invoked after deploy:setup. You can skip this task setting \
        the variable :skip_config_setup_on_shared to true.
      DESC

      task :create, :except => { :no_release => true } do
        Dir.glob("config/deploy/config/#{fetch(:stage)}/*.erb").each do |template_path|
          template = File.read(template_path)
          config_basename = File.basename(template_path).sub(/.erb$/, "")
          put ERB.new(template).result(binding), "#{shared_path}/config/#{config_basename}"
        end
      end

      desc <<-DESC
        [internal] Updates the symlinks for configuration files to the just deployed release.
      DESC

      task :symlink, :except => { :no_release => true } do
        Dir.glob("config/deploy/config/#{fetch(:stage)}/*.erb").each do |template_path|
          config_basename = File.basename(template_path).sub(/.erb$/, "")
          run "ln -nfs #{shared_path}/config/#{config_basename} #{release_path}/config/#{config_basename}"
        end
      end
    end

    after "deploy:setup", "deploy:config:setup", "deploy:config:create" unless fetch(:skip_config_setup_on_shared, false)
    after "deploy:finalize_update", "deploy:config:symlink"
  end
end
