# version of hoptoad's capistrano recipe that passees the stage, rather than rails_env
Capistrano::Configuration.instance(:must_exist).load do
  after "deploy",            "deploy:notify_hoptoad"
  after "deploy:migrations", "deploy:notify_hoptoad"

  namespace :deploy do
    desc "Notify Hoptoad of the deployment"
    task :notify_hoptoad, :except => { :no_release => true } do
      deploy_env = fetch(:hoptoad_env, fetch(:stage, "production"))
      local_user = ENV['USER'] || ENV['USERNAME']
      notify_command = "rake hoptoad:deploy TO=#{deploy_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}"
      notify_command << " API_KEY=#{ENV['API_KEY']}" if ENV['API_KEY']
      puts "Notifying Hoptoad of Deploy (#{notify_command})"
      `#{notify_command}`
      puts "Hoptoad Notification Complete."
    end
  end
end
