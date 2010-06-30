def readme_contents
  IO.read(File.expand_path(File.join(File.dirname(__FILE__), 'README.markdown')))
end

puts readme_contents
