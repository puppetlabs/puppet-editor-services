require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::ValidationProvider' do
  let(:subject) { PuppetLanguageServer::Manifest::ValidationProvider }

  describe '#fix_validate_errors' do
    describe "Given an incomplete manifest which has syntax errors but no lint errors" do
      let(:manifest) { 'user { \'Bob\'' }

      it "should return no changes" do
        problems_fixed, new_content = subject.fix_validate_errors(manifest)
        expect(problems_fixed).to eq(0)
        expect(new_content).to eq(manifest)
      end
    end

    describe "Given a complete manifest which has a single fixable lint errors" do
      let(:manifest) { "
        user { \"Bob\":
          ensure => 'present'
        }"
      }
      let(:new_manifest) { "
        user { 'Bob':
          ensure => 'present'
        }"
      }

      it "should return changes" do
        problems_fixed, new_content = subject.fix_validate_errors(manifest)
        expect(problems_fixed).to eq(1)
        expect(new_content).to eq(new_manifest)
      end
    end

    describe "Given a complete manifest which has multiple fixable lint errors" do
      let(:manifest) { "
        // bad comment
        user { \"Bob\":
          name => 'username',
          ensure => 'present'
        }"
      }
      let(:new_manifest) { "
        # bad comment
        user { 'Bob':
          name   => 'username',
          ensure => 'present'
        }"
      }

      it "should return changes" do
        problems_fixed, new_content = subject.fix_validate_errors(manifest)
        expect(problems_fixed).to eq(3)
        expect(new_content).to eq(new_manifest)
      end
    end


    describe "Given a complete manifest which has unfixable lint errors" do
      let(:manifest) { "
        user { 'Bob':
          name   => 'name',
          ensure => 'present'
        }"
      }

      it "should return no changes" do
        problems_fixed, new_content = subject.fix_validate_errors(manifest)
        expect(problems_fixed).to eq(0)
        expect(new_content).to eq(manifest)
      end
    end

    describe "Given a complete manifest with CRLF which has fixable lint errors" do
      let(:manifest)     { "user { \"Bob\":\r\nensure  => 'present'\r\n}" }
      let(:new_manifest) { "user { 'Bob':\r\nensure  => 'present'\r\n}" }

      it "should preserve CRLF" do
        pending('Release of https://github.com/rodjek/puppet-lint/commit/2a850ab3fd3694a4dd0c4d2f22a1e60b9ca0a495')
        problems_fixed, new_content = subject.fix_validate_errors(manifest)
        expect(problems_fixed).to eq(1)
        expect(new_content).to eq(new_manifest)
      end
    end

    describe "Given a complete manifest which has disabed fixable lint errors" do
      let(:manifest) { "
        user { \"Bob\": # lint:ignore:double_quoted_strings
          ensure  => 'present'
        }"
      }

      it "should return no changes" do
        problems_fixed, new_content = subject.fix_validate_errors(manifest)
        expect(problems_fixed).to eq(0)
        expect(new_content).to eq(manifest)
      end
    end
  end

  describe '#validate' do
    describe "Given an incomplete manifest which has syntax errors" do
      let(:manifest) { 'user { "Bob"' }

      it "should return at least one error" do
        result = subject.validate(manifest)
        expect(result.length).to be > 0
      end
    end

    describe "Given a complete manifest with no validation errors" do
      let(:manifest) { "user { 'Bob': ensure => 'present' }" }

      it "should return an empty array" do
        expect(subject.validate(manifest)).to eq([])
      end
    end

    describe "Given a complete manifest with linting errors" do
      let(:manifest_fixture) { File.join($fixtures_dir,'manifest_with_lint_errors.pp') }
      let(:manifest_lf) { File.open(manifest_fixture, 'r') { |file| file.read } }
      let(:manifest_crlf) { File.open(manifest_fixture, 'r') { |file| file.read }.gsub("\n","\r\n") }

      it "should return same errors for both LF and CRLF line endings" do
        lint_error_lf = subject.validate(manifest_lf)
        lint_error_crlf = subject.validate(manifest_crlf)
        expect(lint_error_crlf).to eq(lint_error_lf)
      end
   end

    describe "Given a complete manifest with a single linting error" do
      let(:manifest) { "
        user { 'Bob':
          ensure  => 'present',
          comment => '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890',
        }"
      }

      it "should return an array with one entry" do
        expect(subject.validate(manifest).count).to eq(1)
      end

      it "should return an entry with linting error information" do
        lint_error = subject.validate(manifest)[0]

        expect(lint_error['source']).to eq('Puppet')
        expect(lint_error['message']).to match('140')
        expect(lint_error['range']).to_not be_nil
        expect(lint_error['code']).to_not be_nil
        expect(lint_error['severity']).to_not be_nil
      end

      context "but disabled" do
        context "on a single line" do
          let(:manifest) { "
            user { 'Bob':
              ensure  => 'present',
              comment => '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'   # lint:ignore:140chars
            }"
          }

          it "should return an empty array" do
            expect(subject.validate(manifest)).to eq([])
          end
        end

        context "in a linting block" do
          let(:manifest) { "
            user { 'Bob':
              ensure  => 'present',
              # lint:ignore:140chars
              comment => '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890',
              # lint:endignore
            }"
          }

          it "should return an empty array" do
            expect(subject.validate(manifest)).to eq([])
          end
        end
      end
    end
  end
end
