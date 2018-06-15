# BlockGraph

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/blockgraph`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blockgraph'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blockgraph

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

# Testing
When you run rspec, you need to run neo4j test server(http://localhost:7475) in advance. Others are the same as normal rspec.

## setup test database
### install test database

```
$ rake neo4j:install[community-3.3.5,test]
```

### change port

```
$ rake neo4j:config[test,7475]
```

### start test database

```
$ rake neo4j:start[test]
```

### create the indexes

```
$ rake neo4j:generate_schema_migration[constraint,BlockGraph::Model::ActiveNodeBase,uuid]
$ rake neo4j:generate_schema_migration[index,BlockGraph::Model::BlockHeader,height]
$ rake neo4j:generate_schema_migration[index,BlockGraph::Model::BlockHeader,block_hash]
$ rake neo4j:generate_schema_migration[index,BlockGraph::Model::Transaction,txid]
$ rake neo4j:generate_schema_migration[index,BlockGraph::Model::AssetId,asset_id]
```

### migrate database

You need to migrate your database.
Run the command below:

```
$ rake neo4j:migrate
```

Did you have error?
Please try again below:

```
$ rake neo4j:migrate NEO4J_URL=[YOUR NEO4J URL]
or
$ rake neo4j:migrate NEO4J_URL=http://user:password@host:port

# e.g.: Execute the below when testing setup. 
$ rake neo4j:migrate NEO4J_URL=http://localhost:7475
```

## Manual build test database
#### OS X
```
$ brew install maven
```

#### Ubuntu
```
apt install maven openjdk-8-jdk
```

download: https://github.com/neo4j/neo4j/archive/3.3.zip
refer how to install: https://github.com/neo4j/neo4j/tree/3.3

```
$ unzip neo4j-3.3
$ cd neo4j-3.3
$ mvn clean install -DskipTests
$ cd packaging/standalone/target
$ tar -zxvf neo4j-community-VERSION-unix.tar.gz
$ mv neo4j-community-VERSION-unix BLOCKGRAPH_HOME/db/neo4j/
$ cd  BlockGRAPH_HOME/db/neo4j
$ mv neo4j-community-VERSION-unix test
```

continue from [change port](#change-port)

## Config Neo4j
edit `db/neo4j/test/conf/neo4j.conf`

### Change LOAD CSV buffer size
add parameter
```
# supported 3.3.6+
dbms.import.csv.buffer_size=4194304 # 4MB
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/blockgraph. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BlockGraph project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/blockgraph/blob/master/CODE_OF_CONDUCT.md).
