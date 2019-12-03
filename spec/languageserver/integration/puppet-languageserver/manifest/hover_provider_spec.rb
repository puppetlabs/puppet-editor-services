require 'spec_helper'

describe 'hover_provider' do
  let(:subject) { PuppetLanguageServer::Manifest::HoverProvider }

  describe '#resolve' do
    let(:content) { <<-EOT
user { 'Bob':
  ensure => 'present',
  name   => 'name',
}

   # Leave this comment.  Needed for the leading whitespace

$test1 = $::operatingsystem
$test2 = $operatingsystem
$test3 = $facts['operatingsystem']

$string1 = 'v1:v2:v3:v4'
$array_var1 = split($string1, ':')

EOT
    }

    before(:each) do
      populate_cache(PuppetLanguageServer::PuppetHelper.cache)
      # Prepopulate the Object Cache with workspace objects
      # Classes / Defined Types
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      obj = random_sidecar_puppet_class
      obj.key = :mock_workspace_class
      list << obj
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!(list, :class, :workspace)
      # Functions
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
      list << random_sidecar_puppet_function
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!(list, :function, :workspace)
      # Types
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
      list << random_sidecar_puppet_type
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!(list, :type, :workspace)
      # Datatypes
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new
      list << random_sidecar_puppet_datatype
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!(list, :datatype, :workspace)
      # Currently the DataTypes are only loaded behind a feature flag. As we only test without
      # the flag, simulate it the purposes of this test
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new
      # The String datatype
      obj = PuppetLanguageServer::Sidecar::Protocol::PuppetDataType.new.from_h!({"key" => "String", "doc"=>"The String core data type", "attributes"=>[], "is_type_alias" => false })
      list << obj
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!(list, :datatype, :default)
    end

    after(:each) do
      # Clear out the Object Cache of workspace objects
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :class, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :function, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :type, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :datatype, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :datatype, :default)
    end

    describe "Given a manifest which has syntax errors" do
      it "should raise an error" do
        expect{subject.resolve('user { "Bob"', 0, 1)}.to raise_error(RuntimeError)
      end
    end

    context 'Given a Puppet Plan', :if => Puppet.tasks_supported? do
      let(:content) { <<-EOT
        plan mymodule::my_plan(
          TargetSpec $webservers,
        ) {
          $webserver_names = get_targets($webservers).map |$n| { $n.name }
        }
        EOT
      }

      it "should not raise an error" do
        result = subject.resolve(content, 0, 1, { :tasks_mode => true})
      end

      it 'should find bolt specific data types' do
        result = subject.resolve(content, 1, 15, { :tasks_mode => true})
        expect(result.contents).to start_with("**TargetSpec** Data Type Alias\n")
      end

      it 'should find bolt specific functions' do
        result = subject.resolve(content, 3, 36, { :tasks_mode => true})
        expect(result.contents).to start_with("**get_targets** Function\n")
      end
    end

    context 'When using Bolt specific information in a normal manifest' do
      let(:content) { <<-EOT
        class mymodule::my_plan(
          TargetSpec $webservers,
        ) {
          $webserver_names = get_targets($webservers).map |$n| { $n.name }
        }
        EOT
      }

      it "should raise an error for Bolt datatypes" do
        expect{subject.resolve(content, 1, 15, { :tasks_mode => false})}.to raise_error(RuntimeError)
      end

      it "should raise an error for Bolt functions" do
        expect{subject.resolve(content, 3, 36, { :tasks_mode => false})}.to raise_error(RuntimeError)
      end
    end

    describe 'when cursor is in the root of the document' do
      let(:line_num) { 5 }
      let(:char_num) { 3 }

      it 'should return nil' do
        result = subject.resolve(content, line_num, char_num)

        expect(result.contents).to eq(nil)
      end
    end

    context "Given a class definition in the manifest" do
      let(:content) { <<-EOT
class Test::NoParams {
  user { 'Alice':
    ensure => 'present',
    name   => 'name',
  }
}

class Test::WithParams (String $version = 'Bob') {
  user { $version:
    ensure => 'present',
    name   => 'name',
  }
}
EOT
      }

      describe 'when cursor is on the class keyword' do
        let(:line_num) { 0 }
        let(:char_num) { 3 }

        it 'should return class description' do
          pending('Not implemented')
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**class** keyword\n")
        end
      end

      describe 'when cursor is on the class name' do
        let(:line_num) { 0 }
        let(:char_num) { 14 }

        it 'should return class description' do
          pending('Not implemented')
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**class** keyword\n")
        end
      end

      describe 'when cursor is on the property type in a class definition' do
        let(:line_num) { 7 }
        let(:char_num) { 27 }

        it 'should return type information' do
          pending('Not implemented')
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**String** keyword\n")
        end
      end

      describe 'when cursor is on the property name in a class definition' do
        let(:line_num) { 7 }
        let(:char_num) { 36 }

        it 'should not return any information' do
          pending('Not implemented')
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to eq('')
        end
      end

      describe 'when cursor is on the property default value in a class definition' do
        let(:line_num) { 7 }
        let(:char_num) { 44 }

        it 'should not return any information' do
          pending('Not implemented')
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to eq('')
        end
      end
    end

    context "Given a resource (Puppet Type) in the manifest" do
      let(:content) { <<-EOT
user { 'Bob':
  ensure => 'present',
  name   => 'name',
}
EOT
      }

      describe 'when cursor is on the resource type name' do
        let(:line_num) { 0 }
        let(:char_num) { 3 }

        it 'should return resource description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**user** Resource\n")
        end
      end

      describe 'when cursor is on the name of the resource' do
        let(:line_num) { 0 }
        let(:char_num) { 10 }

        it 'should return resource description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**user** Resource\n")
        end
      end

      describe 'when cursor is on the whitespace before a property name' do
        let(:line_num) { 2 }
        let(:char_num) { 1 }

        it 'should return resource description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**user** Resource\n")
        end
      end

      describe 'when cursor is on the property name' do
        let(:line_num) { 1 }
        let(:char_num) { 5 }

        it 'should return property description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**ensure** Property\n")
        end
      end

      describe 'when cursor is on the "=>" after a property name' do
        let(:line_num) { 1 }
        let(:char_num) { 10 }

        it 'should return property description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**ensure** Property\n")
        end
      end

      describe 'when cursor is on the parameter name' do
        let(:line_num) { 2 }
        let(:char_num) { 5 }

        it 'should return parameter description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**name** Parameter\n")
        end
      end

      describe 'when cursor is on the "=>" after a parameter name' do
        let(:line_num) { 2 }
        let(:char_num) { 10 }

        it 'should return parameter description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**name** Parameter\n")
        end
      end
    end

    context "Given a resource (Puppet Class/Defined Type) in the manifest" do
      let(:content) { <<-EOT
mock_workspace_class { 'Dee':
  attr_name1 => 'string1',
  attr_name2 => 'string1',
}

::mock_workspace_class { 'Dah': }
EOT
      }

      describe 'when cursor is on the resource type name' do
        let(:line_num) { 0 }
        let(:char_num) { 3 }

        it 'should return resource description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**mock_workspace_class** Resource\n")
        end
      end

      describe 'when cursor is on the top-scoped resource type name' do
        let(:line_num) { 5 }
        let(:char_num) { 5 }

        it 'should return resource description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**mock_workspace_class** Resource\n")
        end
      end

      describe 'when cursor is on the name of the resource' do
        let(:line_num) { 0 }
        let(:char_num) { 26 }

        it 'should return resource description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**mock_workspace_class** Resource\n")
        end
      end

      describe 'when cursor is on the whitespace before a Parameter name' do
        let(:line_num) { 2 }
        let(:char_num) { 1 }

        it 'should return resource description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**mock_workspace_class** Resource\n")
        end
      end

      describe 'when cursor is on the parameter name' do
        let(:line_num) { 1 }
        let(:char_num) { 5 }

        it 'should return parameter description' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**attr_name1** Parameter\n")
        end
      end

      describe 'when cursor is on the "=>" after a parameter name' do
        let(:line_num) { 1 }
        let(:char_num) { 15 }

        it 'should return parameter description' do
          result = subject.resolve(content, line_num, char_num)
          expect(result.contents).to start_with("**attr_name1** Parameter\n")
        end
      end
    end

    context "Given a facts variable in the manifest" do
      let(:content) { <<-EOT
$test1 = $::operatingsystem
$test2 = $operatingsystem
$test3 = $facts['operatingsystem']
EOT
      }

      describe 'when cursor is on $::FACTNAME' do
        let(:line_num) { 0 }
        let(:char_num) { 16 }

        it 'should return fact information' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**operatingsystem** Fact\n")
        end
      end

      describe 'when cursor is on $FACTNAME' do
        let(:line_num) { 1 }
        let(:char_num) { 16 }

        it 'should return fact information' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**operatingsystem** Fact\n")
        end
      end

      describe 'when cursor is on $facts[FACTNAME]' do
        let(:line_num) { 2 }
        let(:char_num) { 12 }

        it 'should return fact information' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**operatingsystem** Fact\n")
        end
      end

      describe 'when cursor is inside $facts[FACTNAME]' do
        let(:line_num) { 2 }
        let(:char_num) { 22 }

        it 'should return fact information' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**operatingsystem** Fact\n")
        end
      end
    end

    context "Given a function in the manifest" do
      let(:content) { <<-EOT
$string     = 'v1.v2:v3.v4'
$array_var1 = split($string, ':')
EOT
      }

      describe 'when cursor is on function name' do
        let(:line_num) { 1 }
        let(:char_num) { 17 }

        it 'should return function information' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**split** Function\n")
        end
      end
    end

    context "Given a resource in an else block" do
      let(:content) { <<-EOF
class firewall {
  if(true) {
  } else {
    service { 'service':
      ensure    => running
    }
  }
}
    EOF
      }

      describe 'when cursor is hovering on else branch' do
        let(:line_num) { 2 }
        let(:char_num) { 6 }
        it 'should not complete to service resource' do
          pending("(PUP-7668) parser is assigning an incorrect offset")

          result = subject.resolve(content, line_num, char_num)
          expect(result.contents).not_to start_with("**service** Resource\n")
        end
      end

      describe 'when cursor is hovering on service resource' do
        let(:line_num) { 3 }
        let(:char_num) { 6 }
        it 'should complete to service resource documentation' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**service** Resource\n")
        end
      end
    end

    context "Given a class with data types" do
      let(:content) { <<-EOF
class module::foo (
  String                      $load_balancer,
  Variant[String[1], Boolean] $frontends = 'Hello',
  Integer[1,10]               $blah,
  Enum["running", "stopped"]  $enum,
) {
  Stdlib::Windowspath $test = false
}
    EOF
      }

      describe 'when cursor is on bare datatype name' do
        let(:line_num) { 1 }
        let(:char_num) { 6 }
        it 'should complete an inbuilt Puppet type' do
          result = subject.resolve(content, line_num, char_num)

          expect(result.contents).to start_with("**String** Data Type\n")
        end
      end

      # describe 'when cursor is hovering on service resource' do
      #   let(:line_num) { 3 }
      #   let(:char_num) { 6 }
      #   it 'should complete to service resource documentation' do
      #     result = subject.resolve(content, line_num, char_num)

      #     expect(result.contents).to start_with("**service** Resource\n")
      #   end
      # end
    end
  end
end
