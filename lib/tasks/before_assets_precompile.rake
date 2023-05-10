task :before_assets_precompile do
  system('apk add --no-cache git openssh')
  puts "BEFORE ASSETS PRECOMPILE TASK RUNNING"
end

Rake::Task['assets:precompile'].enhance ['before_assets_precompile']