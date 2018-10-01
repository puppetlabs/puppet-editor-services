require 'spec_helper'

describe 'PuppetLanguageServer::Puppetfile::ValidationProvider' do
  let(:subject) { PuppetLanguageServer::Puppetfile::ValidationProvider }

  describe "#validate" do
    context 'with an empty Puppetfile' do
      let(:content) { '' }
      it 'should return no validation errors' do
        result = subject.validate(content, nil)

        expect(result).to eq([])
      end
    end

    context 'with a valid Puppetfile' do
      let(:content) do <<-EOT
        forge 'https://forge.puppetlabs.com/'

        # Modules from the Puppet Forge
        mod 'puppetlabs-somemodule',      '1.0.0'

        # Git style modules
        mod 'gitcommitmodule',
          :git => 'https://github.com/username/repo',
          :commit => 'abc123'
        mod 'gittagmodule',
          :git => 'https://github.com/username/repo',
          :tag => '0.1'

        # Svn style modules
        mod 'svnmodule',
          :svn => 'svn://host/repo',
          :rev => 'abc123'

        # local style modules
        mod 'localmodule',
          :local => 'true'
        EOT
      end

      it 'should return no validation errors' do
        result = subject.validate(content, nil)

        expect(result).to eq([])
      end
    end

    context 'with a syntax error in the Puppetfile' do
      let(:content) do <<-EOT
        forge 'https://forge.puppetlabs.com/'

        # Modules from the Puppet Forge
        mod 'puppetlabs-somemodule',      '1.0.0'

        # Git style modules
        mod 'gitcommitmodule',
          :git => 'https://github.com/username/repo',
          :commit => 'abc123'
        mod 'gittagmodule',
          :git => 'https://github.com/username/repo',
          :tag => '0.1'
        } # I am a sytnax error
        EOT
      end

      it 'should return a validation error' do
        lint_error = subject.validate(content, nil)[0]

        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match('syntax error')
        expect(lint_error.range).to_not be_nil
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
      end
    end

    context 'with a loading error in the Puppetfile' do
      let(:content) do <<-EOT
        forge 'https://forge.puppetlabs.com/'

        # Modules from the Puppet Forge
        mod 'puppetlabs-somemodule',      '1.0.0'

        require 'not_loadable' # I am a load error

        # Git style modules
        mod 'gitcommitmodule',
          :git => 'https://github.com/username/repo',
          :commit => 'abc123'
        mod 'gittagmodule',
          :git => 'https://github.com/username/repo',
          :tag => '0.1'
        EOT
      end

      it 'should return a validation error' do
        lint_error = subject.validate(content, nil)[0]

        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match('not_loadable')
        expect(lint_error.range.start.line).to eq(5)
        expect(lint_error.range.end.line).to eq(5)
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
      end
    end

    context 'with a standard error in the Puppetfile' do
      let(:content) do <<-EOT
        forge 'https://forge.puppetlabs.com/'

        # Modules from the Puppet Forge
        mod 'puppetlabs-somemodule',      '1.0.0'

        # Git style modules
        mod 'gitcommitmodule',
          :git => 'https://github.com/username/repo',
          :commit => 'abc123'

        raise 'A Mock Runtime Error'

        mod 'gittagmodule',
          :git => 'https://github.com/username/repo',
          :tag => '0.1'
        EOT
      end

      it 'should return a validation error' do
        lint_error = subject.validate(content, nil)
        expect(lint_error.count).to eq(1)
        lint_error = lint_error[0]

        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match('A Mock Runtime Error')
        expect(lint_error.range.start.line).to eq(10)
        expect(lint_error.range.end.line).to eq(10)
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
      end
    end

    context 'with an unknown method in the Puppetfile' do
      let(:content) do <<-EOT
        forge 'https://forge.puppetlabs.com/'

        # Modules from the Puppet Forge
        mod 'puppetlabs-somemodule',      '1.0.0'

        # Git style modules
        mod 'gitcommitmodule',
          :git => 'https://github.com/username/repo',
          :commit => 'abc123'
        mod_BROKEN 'gittagmodule',
          :git => 'https://github.com/username/repo',
          :tag => '0.1'
        EOT
      end

      it 'should return a validation error on the specified line' do
        lint_error = subject.validate(content, nil)[0]

        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match('mod_BROKEN')
        expect(lint_error.range.start.line).to eq(9)
        expect(lint_error.range.end.line).to eq(9)
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
      end
    end

    context 'with an unknown or invalid module parameter set' do
      let(:content) do <<-EOT
        forge 'https://forge.puppetlabs.com/'

        mod 'fifthelement',
          :i_am_a_meat_popsicle => true
        EOT
      end

      it 'should return a validation error' do
        lint_error = subject.validate(content, nil)[0]

        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match('doesn\'t have an implementation')
        expect(lint_error.range.start.line).to eq(2)
        expect(lint_error.range.end.line).to eq(2)
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
      end
    end

    context 'with duplicate, valid and invalid modules defined' do
      let(:content) do <<-EOT
        forge 'https://forge.puppetlabs.com/'

        mod 'duplicate-module',      '1.0.0'

        mod 'duplicatemodule',
          :git => 'https://github.com/username/repo'

        mod 'duplicatemodule',
          :i_am_a_meat_popsicle => true
        EOT
      end

      it 'should return all validation error' do
        lint_errors = subject.validate(content, nil)
        expect(lint_errors.count).to eq(3)

        lint_error = lint_errors[0]
        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match('doesn\'t have an implementation')
        expect(lint_error.range.start.line).to eq(7)
        expect(lint_error.range.end.line).to eq(7)
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)

        lint_error = lint_errors[1]
        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match(/Duplicate.+duplicatemodule/)
        expect(lint_error.range.start.line).to eq(4)
        expect(lint_error.range.end.line).to eq(4)
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)

        lint_error = lint_errors[2]
        expect(lint_error.source).to eq('Puppet')
        expect(lint_error.message).to match(/Duplicate.+duplicatemodule/)
        expect(lint_error.range.start.line).to eq(7)
        expect(lint_error.range.end.line).to eq(7)
        expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
      end
    end

    # Git style module tests
    context 'with a single git style module' do
      context 'with valid minimal parameters for a git module' do
        it 'should return no validation errors' do
          content = <<-EOT
            mod 'gitcommitmodule',
              :git => 'https://github.com/username/repo'
            EOT

          result = subject.validate(content, nil)

          expect(result).to eq([])
        end
      end
    end

    # Svn style module tests
    context 'with a single svn style module' do
      context 'with valid minimal parameters for a svn module' do
        it 'should return no validation errors' do
          content = <<-EOT
            mod 'svnmodule',
              :svn => 'svn://host/repo'
            EOT

          result = subject.validate(content, nil)

          expect(result).to eq([])
        end
      end
    end

    # Local style module tests
    context 'with a single local style module' do
      context 'with valid parameters for a local module' do
        it 'should return no validation errors' do
          content = <<-EOT
            mod 'localmodule',
              :local => true
            EOT

          result = subject.validate(content, nil)

          expect(result).to eq([])
        end
      end
    end

    # Forge style module tests
    context 'with a single forge style module' do
      good_module_names = ['puppetlabs-modulename', 'puppetlabs/modulename']
      bad_module_names = ['puppetlabs:modulename', 'puppetlabs\\modulename', 'puppetlabs modulename', 'puppetlabsmodulename']

      good_module_versions = ['1.0.0', '10.1.2']
      bad_module_versions = ['1.x', '1.2', '1.0.xxx0']

      good_module_name = good_module_names[0]
      good_module_version = good_module_versions[0]

      context 'with a valid module version' do
        good_module_versions.each do |testcase|
          it "should return no validation errors for a module version of #{testcase}" do
            content = <<-EOT
              forge 'https://forge.puppetlabs.com/'

              # Modules from the Puppet Forge
              mod '#{good_module_name}', '#{testcase}'
              EOT

            result = subject.validate(content, nil)

            expect(result).to eq([])
          end
        end
      end

      context 'with an invalid module version' do
        bad_module_versions.each do |testcase|
          it "should return a validation error for a module version of #{testcase}" do
            content = <<-EOT
              forge 'https://forge.puppetlabs.com/'

              # Modules from the Puppet Forge
              mod '#{good_module_name}', '#{testcase}'
              EOT

            lint_error = subject.validate(content, nil)
            expect(lint_error.count).to eq(1)
            lint_error = lint_error[0]

            expect(lint_error.source).to eq('Puppet')
            # The horrible gsub is for backslashes in regexes
            expect(lint_error.message).to match(testcase.gsub('\\','\\\\\\\\'))
            expect(lint_error.range.start.line).to eq(3)
            expect(lint_error.range.end.line).to eq(3)
            expect(lint_error.range).to_not be_nil
            expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
          end
        end
      end

      context 'with a valid module name' do
        good_module_names.each do |testcase|
          it "should return no validation errors for a module name of #{testcase}" do
            content = <<-EOT
              forge 'https://forge.puppetlabs.com/'

              # Modules from the Puppet Forge
              mod '#{testcase}', '#{good_module_version}'
              EOT

            result = subject.validate(content, nil)

            expect(result).to eq([])
          end
        end
      end

      context 'with an invalid module name' do
        bad_module_names.each do |testcase|
          it "should return a validation error for a module name of #{testcase}" do
            content = <<-EOT
              forge 'https://forge.puppetlabs.com/'

              # Modules from the Puppet Forge
              mod '#{testcase}', '#{good_module_version}'
              EOT

            lint_error = subject.validate(content, nil)
            expect(lint_error.count).to eq(1)
            lint_error = lint_error[0]

            expect(lint_error.source).to eq('Puppet')
            # The horrible gsub is for backslashes in regexes
            expect(lint_error.message).to match(testcase.gsub('\\','\\\\\\\\'))
            expect(lint_error.range.start.line).to eq(3)
            expect(lint_error.range.end.line).to eq(3)
            expect(lint_error.range).to_not be_nil
            expect(lint_error.severity).to eq(LSP::DiagnosticSeverity::ERROR)
          end
        end
      end
    end
  end
end
