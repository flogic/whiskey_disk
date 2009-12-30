namespace :deploy do
  namespace :staging do
    task :post_setup do
      puts "This is my local post_setup hook."
    end

    task :post_deploy do
      puts "This is my local post_deploy hook."
    end
  end
end
