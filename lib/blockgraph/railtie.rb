module BlockGraph
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'blockgraph/tasks/migration.rake'
    end
  end
end
