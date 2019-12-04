require 'spec_helper'

RSpec.shared_examples "a single definition result" do |filename_regex|
  it "should return a single definition result which matches #{filename_regex.to_s}" do
    result = subject.find_definition(session_state, content, line_num, char_num)

    expect(result).to be_a(Array)
    expect(result.count).to eq(1)
    expect(result[0].uri).to match(filename_regex)
    expect(result[0].range.start.line).to_not be_nil
    expect(result[0].range.start.character).to_not be_nil
    expect(result[0].range.end.line).to_not be_nil
    expect(result[0].range.end.character).to_not be_nil
  end
end

def puppetclass_cache_object(key, source)
  random_sidecar_puppet_class(key).tap do |obj|
    obj.source = source
    obj.calling_source = source
  end
end

describe 'definition_provider' do
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, :connection_id => 'mock') }
  let(:subject) { PuppetLanguageServer::Manifest::DefinitionProvider }

  before(:each) do
    # Until the PuppetHelper has finished refactoring, we need to mock
    # the items in both cache objects
    populate_cache(PuppetLanguageServer::PuppetHelper.cache)
    populate_cache(session_state.object_cache)
    PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([
      puppetclass_cache_object(:deftypeone, '/root/deftypeone.pp'),
      puppetclass_cache_object(:puppetclassone, '/root/puppetclassone.pp'),
      puppetclass_cache_object(:testclasses, '/root/init.pp'),
      puppetclass_cache_object(:"testclasses::nestedclass", '/root/nestedclass.pp')
    ], :class, :rspec)
  end

  after(:all) do
    PuppetLanguageServer::PuppetHelper.cache.remove_section!(:class, :rspec)
  end

  describe '#find_defintion' do
    context 'Given a Puppet Plan', :if => Puppet.tasks_supported? do
      let(:content) { <<-EOT
        plan mymodule::my_plan(
        ) {
        }
        EOT
      }
      it "should not raise an error" do
        result = subject.find_definition(session_state, content, 0, 1, { :tasks_mode => true})
      end
    end

    context 'When cursor is on a function name' do
      let(:content) { <<-EOT
class Test::NoParams {
  alert('This is an alert message')
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 5 }

      it_should_behave_like "a single definition result", /alert\.rb/
    end

    context 'When cursor is on a custom puppet type' do
      let(:content) { <<-EOT
class Test::NoParams {
  user { 'foo':
    ensure => 'present',
    name   => 'name',
  }
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 5 }

      it_should_behave_like "a single definition result", /user\.rb/
    end

    context 'When cursor is on a puppet class' do
      let(:content) { <<-EOT
class Test::NoParams {
  class { 'testclasses':
    ensure => 'present',
  }
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 13 }

      it_should_behave_like "a single definition result", /init\.pp/
    end

    context 'When cursor is on a root puppet class' do
      let(:content) { <<-EOT
class Test::NoParams {
  class { '::testclasses':
    ensure => 'present',
  }
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 13 }

      it_should_behave_like "a single definition result", /init\.pp/
    end

    context 'When cursor is on a fully qualified puppet class' do
      let(:content) { <<-EOT
class Test::NoParams {
  class { 'testclasses::nestedclass':
    ensure => 'present',
  }
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 13 }

      it_should_behave_like "a single definition result", /nestedclass\.pp/
    end

    context 'When cursor is on a defined type' do
      let(:content) { <<-EOT
class Test::NoParams {
  deftypeone { 'foo':
    ensure => 'present',
  }
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 5 }

      it_should_behave_like "a single definition result", /deftypeone\.pp/
    end

    context 'When cursor is on a puppet class' do
      let(:content) { <<-EOT
class Test::NoParams {
  puppetclassone { 'foo':
    ensure => 'present',
  }
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 5 }

      it_should_behave_like "a single definition result", /puppetclassone\.pp/
    end

    context 'When cursor is on a classname for an include statement' do
      let(:content) { <<-EOT
class Test::NoParams {
  include puppetclassone
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 14 }

      it_should_behave_like "a single definition result", /puppetclassone\.pp/
    end

    context 'When cursor is on a fully qualified classname for an include statement' do
      let(:content) { <<-EOT
class Test::NoParams {
  include testclasses::nestedclass
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 14 }

      it_should_behave_like "a single definition result", /nestedclass\.pp/
    end

    context 'When cursor is on a root classname for an include statement' do
      let(:content) { <<-EOT
class Test::NoParams {
  include ::puppetclassone
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 14 }

      it_should_behave_like "a single definition result", /puppetclassone\.pp/
    end

    context 'When cursor is on a function name for an include statement' do
      let(:content) { <<-EOT
class Test::NoParams {
  include puppetclassone
}
EOT
      }
      let(:line_num) { 1 }
      let(:char_num) { 5 }

      it_should_behave_like "a single definition result", /include\.rb/
    end
  end
end
