require 'resque-delayed'

# require 'resque-delayed/tasks'
namespace :resque_delayed do

  desc "Start a Resque::Delayed worker"
  task :work do
    begin
      worker = Resque::Delayed::Worker.new
      worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      worker.very_verbose = ENV['VVERBOSE']
    end

    if ENV['PIDFILE']
      File.open(ENV['PIDFILE'], 'w') { |f| f << worker.pid }
    end

    worker.log "Starting Resque::Delayed worker #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Migrate Resque::Delayed queue to new redis key after 1.1.0 upgrade"
  task :migrate_queue_key do
    redis = Resque.redis.instance_variable_get :@redis

    old_key = ""
    new_key = "resque:Resque::Delayed:internal"

    redis.zrange(old_key, 0, -1, :withscores => true).each_slice(2).each do |key, score|
      redis.zadd new_key, score, key
    end

    redis.del old_key
  end
end
