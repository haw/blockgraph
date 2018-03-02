require 'spec_helper'

RSpec.describe BlockGraph::CLI do

  describe '#start', cli: true do
    it "use -c option, start blockgraph_daemon" do
      args = ["start", "-c", "spec/fixtures/default_config.yml"]
      content = capture(:stdout) { BlockGraph::CLI.start(args) }
      expect(content).to match(/BlockGraphDaemon started./m)
    end

    it "use -p or --pid option, create <pidfile>." do
      args = ["start", "-c", "spec/fixtures/default_config.yml"]
      args << "-p"
      args << "foo.pid"
      expect {
        capture(:stdout) { BlockGraph::CLI.start(args) }
        sleep 3
      }.to change { File.exist?("./foo.pid") }.from(false).to be_truthy

      args = ["start", "-c", "spec/fixtures/default_config.yml"]
      args << "--pid"
      args << "bar.pid"
      expect {
        capture(:stdout) { BlockGraph::CLI.start(args) }
        sleep 3
      }.to change { File.exist?("./bar.pid") }.from(false).to be_truthy
    end

    it "use -l or --log option, create <logfile>." do
      args = ["start", "-c", "spec/fixtures/default_config.yml"]
      args << "-l"
      args << "foo.log"
      expect {
        capture(:stdout) { BlockGraph::CLI.start(args) }
        sleep 3
      }.to change { File.exist?("./foo.log") }.from(false).to be_truthy

      args = ["start", "-c", "spec/fixtures/default_config.yml"]
      args << "--log=bar.log"
      expect {
        capture(:stdout) { BlockGraph::CLI.start(args) }
        sleep 3
      }.to change { File.exist?("./bar.log") }.from(false).to be_truthy
    end
  end

  describe "#stop", cli: true do
    it "-c is not required" do
      args = ["stop", "-c", "spec/fixtures/default_config.yml"]
      content = capture(:stderr) { BlockGraph::CLI.start(args) }
      expect(content).to match(/Usage: "\w+ stop"/m)
    end
  end

  describe "#status", cli: true do
    it "-c is not required" do
      args = ["status", "-c", "spec/fixtures/default_config.yml"]
      content = capture(:stderr) { BlockGraph::CLI.start(args) }
      expect(content).to match(/Usage: "\w+ status"/m)
    end
  end

  describe "#restart", cli: true do
    it "use -c option, restart blockgraph daemon" do
      args = ["restart", "-c", "spec/fixtures/default_config.yml"]
      content = capture(:stdout) { BlockGraph::CLI.start(args) }
      expect(content).to match(/PID file not found. Is the daemon started?/m)
    end
  end

end
