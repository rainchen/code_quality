class CodeQuality::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/code_quality.rake'
  end
end