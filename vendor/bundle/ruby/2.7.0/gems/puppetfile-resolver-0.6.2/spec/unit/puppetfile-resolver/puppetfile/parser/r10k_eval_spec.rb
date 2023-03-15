require 'spec_helper'

require 'puppetfile-resolver/puppetfile/parser/r10k_eval'

RSpec.shared_examples "a puppetfile parser with valid content" do
  let(:puppetfile_content) do
    <<-EOT
    forge 'https://fake-forge.puppetlabs.com/'

    mod 'puppetlabs-forge_fixed_ver', '1.0.0'
    mod 'puppetlabs-forge_latest',    :latest

    mod 'git_branch',
      :git => 'git@github.com:puppetlabs/puppetlabs-git_branch.git',
      :branch => 'branch'

    mod 'git_ref',
    :git => 'git@github.com:puppetlabs/puppetlabs-git_ref.git',
    :ref => 'branch'

    mod 'git_commit',
      :git => 'git@github.com:puppetlabs/puppetlabs-git_commit.git',
      :commit => 'abc123'

    mod 'git_tag',
      :git => 'git@github.com:puppetlabs/puppetlabs-git_tag.git',
      :tag => '0.1'

    mod 'local', :local => 'some/path'

    mod 'svn_min', :svn => 'some-svn-repo'

    mod 'puppetlabs-forge_missing'
    EOT
  end

  let(:puppetfile) { subject.parse(puppetfile_content) }

  def get_module(document, title)
    document.modules.find { |mod| mod.title == title }
  end

  it "should set the forge uri" do
    expect(puppetfile.forge_uri).to eq('https://fake-forge.puppetlabs.com/')
  end

  it "should return the Puppetfile content" do
    expect(puppetfile.content).to eq(puppetfile_content)
  end

  it "should detect all of the modules" do
    expect(puppetfile.modules.count).to eq(9)
  end

  it "should not set any resolver flags" do
    expect(puppetfile.modules).to all(have_attributes(:resolver_flags => []))
  end

  context 'with Forge modules' do
    it 'should detect forge fixed version modules' do
      mod = get_module(puppetfile, 'puppetlabs-forge_fixed_ver')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::FORGE_MODULE)
      expect(mod.title).to eq('puppetlabs-forge_fixed_ver')
      expect(mod.owner).to eq('puppetlabs')
      expect(mod.name).to eq('forge_fixed_ver')
      expect(mod.version).to eq('=1.0.0')
      expect(mod.location.start_line).to eq(2)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(2)
      expect(mod.location.end_char).to  be_nil
    end

    it 'should detect forge latest version modules' do
      mod = get_module(puppetfile, 'puppetlabs-forge_latest')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::FORGE_MODULE)
      expect(mod.title).to eq('puppetlabs-forge_latest')
      expect(mod.owner).to eq('puppetlabs')
      expect(mod.name).to eq('forge_latest')
      expect(mod.version).to eq(:latest)
      expect(mod.location.start_line).to eq(3)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(3)
      expect(mod.location.end_char).to  be_nil
    end

    it 'should detect missing latest version modules as latest' do
      mod = get_module(puppetfile, 'puppetlabs-forge_missing')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::FORGE_MODULE)
      expect(mod.title).to eq('puppetlabs-forge_missing')
      expect(mod.owner).to eq('puppetlabs')
      expect(mod.name).to eq('forge_missing')
      expect(mod.version).to eq(:latest)
      expect(mod.location.start_line).to eq(25)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(25)
      expect(mod.location.end_char).to  be_nil
    end
  end

  context 'with Git modules' do
    it 'should detect git branch modules' do
      mod = get_module(puppetfile, 'git_branch')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::GIT_MODULE)
      expect(mod.title).to eq('git_branch')
      expect(mod.owner).to be_nil
      expect(mod.name).to eq('git_branch')
      expect(mod.version).to be_nil
      expect(mod.remote).to eq('git@github.com:puppetlabs/puppetlabs-git_branch.git')
      expect(mod.ref).to eq('branch')
      expect(mod.commit).to be_nil
      expect(mod.tag).to be_nil
      expect(mod.location.start_line).to eq(5)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(5)
      expect(mod.location.end_char).to  be_nil
    end

    it 'should detect git ref modules' do
      mod = get_module(puppetfile, 'git_ref')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::GIT_MODULE)
      expect(mod.title).to eq('git_ref')
      expect(mod.owner).to be_nil
      expect(mod.name).to eq('git_ref')
      expect(mod.version).to be_nil
      expect(mod.remote).to eq('git@github.com:puppetlabs/puppetlabs-git_ref.git')
      expect(mod.ref).to eq('branch')
      expect(mod.commit).to be_nil
      expect(mod.tag).to be_nil
      expect(mod.location.start_line).to eq(9)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(9)
      expect(mod.location.end_char).to  be_nil
    end

    it 'should detect git commit modules' do
      mod = get_module(puppetfile, 'git_commit')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::GIT_MODULE)
      expect(mod.title).to eq('git_commit')
      expect(mod.owner).to be_nil
      expect(mod.name).to eq('git_commit')
      expect(mod.version).to be_nil
      expect(mod.remote).to eq('git@github.com:puppetlabs/puppetlabs-git_commit.git')
      expect(mod.ref).to be_nil
      expect(mod.commit).to eq('abc123')
      expect(mod.tag).to be_nil
      expect(mod.location.start_line).to eq(13)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(13)
      expect(mod.location.end_char).to  be_nil
    end

    it 'should detect git tag modules' do
      mod = get_module(puppetfile, 'git_tag')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::GIT_MODULE)
      expect(mod.title).to eq('git_tag')
      expect(mod.owner).to be_nil
      expect(mod.name).to eq('git_tag')
      expect(mod.version).to be_nil
      expect(mod.remote).to eq('git@github.com:puppetlabs/puppetlabs-git_tag.git')
      expect(mod.ref).to be_nil
      expect(mod.commit).to be_nil
      expect(mod.tag).to eq('0.1')
      expect(mod.location.start_line).to eq(17)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(17)
      expect(mod.location.end_char).to  be_nil
    end
  end

  context 'with Local modules' do
    it 'should detect local modules' do
      mod = get_module(puppetfile, 'local')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::LOCAL_MODULE)
      expect(mod.title).to eq('local')
      expect(mod.owner).to be_nil
      expect(mod.name).to eq('local')
      expect(mod.version).to be_nil
      expect(mod.location.start_line).to eq(21)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(21)
      expect(mod.location.end_char).to  be_nil
    end
  end

  context 'with SVN modules' do
    it 'should detect svn modules' do
      mod = get_module(puppetfile, 'svn_min')

      expect(mod.module_type).to eq(PuppetfileResolver::Puppetfile::SVN_MODULE)
      expect(mod.title).to eq('svn_min')
      expect(mod.owner).to be_nil
      expect(mod.name).to eq('svn_min')
      expect(mod.version).to be_nil
      expect(mod.remote).to eq('some-svn-repo')
      expect(mod.location.start_line).to eq(23)
      expect(mod.location.start_char).to be_nil
      expect(mod.location.end_line).to eq(23)
      expect(mod.location.end_char).to  be_nil
    end
  end
end

RSpec.shared_examples "a puppetfile parser with magic comments" do
  def get_module(document, title)
    document.modules.find { |mod| mod.title == title }
  end

  context 'with differnt types of magic comments' do
    let(:flag_name) { 'Dependency/Puppet' }
    let(:flag) { PuppetfileResolver::Puppetfile::DISABLE_PUPPET_DEPENDENCY_FLAG }
    let(:flag_name2) { 'Dependency/All' }
    let(:flag2) { PuppetfileResolver::Puppetfile::DISABLE_ALL_DEPENDENCIES_FLAG }

    let(:puppetfile_content) do
      <<-EOT
      forge 'https://fake-forge.puppetlabs.com/'

      mod 'puppetlabs-inline', :latest # resolver:disable #{flag_name}

      # resolver:disable #{flag_name}
      mod 'puppetlabs-block', :latest
      # resolver:enable #{flag_name}

      # resolver:disable #{flag_name}
      # resolver:disable #{flag_name}
      mod 'puppetlabs-overlap1', :latest
      # resolver:enable #{flag_name}
      # resolver:enable #{flag_name}

      # resolver:disable #{flag_name}
      mod 'puppetlabs-overlap2',
        :git => 'git@github.com:puppetlabs/puppetlabs-git_branch.git',
        # resolver:enable #{flag_name}
        :branch => 'branch'

      mod 'puppetlabs-overlap3',
        # resolver:disable #{flag_name}
        :git => 'git@github.com:puppetlabs/puppetlabs-git_branch.git',
        :branch => 'branch'
        # resolver:enable #{flag_name}


      mod 'puppetlabs-nomagic', :latest
      EOT
    end
    let(:puppetfile) { subject.parse(puppetfile_content) }

    it "should freeze the resolver flags" do
      puppetfile.modules.each do |mod|
        expect(mod.resolver_flags).to be_frozen
      end
    end

    it 'should add the flag with inline magic comments' do
      mod = get_module(puppetfile, 'puppetlabs-inline')
      expect(mod.resolver_flags).to eq([flag])
    end

    it 'should add the flag with magic comment ranges' do
      mod = get_module(puppetfile, 'puppetlabs-block')
      expect(mod.resolver_flags).to eq([flag])
    end

    it 'should ignore overlapping ranges and only add the flag once' do
      mod = get_module(puppetfile, 'puppetlabs-overlap1')
      expect(mod.resolver_flags).to eq([flag])
    end

    it 'should add the flag with magic comment range if it spans the beginning of a multiline module definition' do
      mod = get_module(puppetfile, 'puppetlabs-overlap2')
      expect(mod.resolver_flags).to eq([flag])
    end

    it 'should add the flag with magic comment range if it spans the end of multiline module definition' do
      pending('The Ruby Eval method can\'t detect module definition spans and only looks at the first line')
      mod = get_module(puppetfile, 'puppetlabs-overlap3')
      expect(mod.resolver_flags).to eq([flag])
    end

    it 'should not add flags to unaffected modules' do
      mod = get_module(puppetfile, 'puppetlabs-nomagic')
      expect(mod.resolver_flags).to eq([])
    end

    context 'with a flag that is never re-enabled' do
      let(:puppetfile_content) do
        <<-EOT
        forge 'https://fake-forge.puppetlabs.com/'

        mod 'puppetlabs-nomagic', :latest

        # resolver:disable #{flag_name}

        mod 'puppetlabs-block', :latest
        EOT
      end

      it 'should not add flags to unaffected modules' do
        mod = get_module(puppetfile, 'puppetlabs-nomagic')
        expect(mod.resolver_flags).to eq([])
      end

      it 'should add the flag to the subsequent modules' do
        mod = get_module(puppetfile, 'puppetlabs-block')
        expect(mod.resolver_flags).to eq([flag])
      end
    end

    context 'with a flag that is specified more than once' do
      let(:puppetfile_content) do
        <<-EOT
        forge 'https://fake-forge.puppetlabs.com/'

        mod 'puppetlabs-block', :latest # resolver:disable #{flag_name},#{flag_name},#{flag_name},#{flag_name} Some reason
        EOT
      end

      it 'should add the flag only once' do
        mod = get_module(puppetfile, 'puppetlabs-block')
        expect(mod.resolver_flags).to eq([flag])
      end
    end

    context 'with multiple valid flags' do
      let(:puppetfile_content) do
        <<-EOT
        forge 'https://fake-forge.puppetlabs.com/'

        mod 'puppetlabs-block', :latest # resolver:disable #{flag_name},#{flag_name2} Another good reason reason
        EOT
      end

      it 'should add the flags' do
        mod = get_module(puppetfile, 'puppetlabs-block')
        expect(mod.resolver_flags).to eq([flag, flag2])
      end
    end

    context 'with invalid flags' do
      let(:puppetfile_content) do
        <<-EOT
        forge 'https://fake-forge.puppetlabs.com/'

        mod 'puppetlabs-block', :latest # resolver:disable #{flag_name},missing,foo,bar baz Another good reason reason
        EOT
      end

      it 'should add the valid flags and ignore the invalid flags' do
        mod = get_module(puppetfile, 'puppetlabs-block')
        expect(mod.resolver_flags).to eq([flag])
      end
    end
  end

  context 'with all available flags' do
    let(:puppetfile_content) do
      <<-EOT
      forge 'https://fake-forge.puppetlabs.com/'

      mod 'puppetlabs-magic1', :latest # resolver:disable Dependency/Puppet
      mod 'puppetlabs-magic2', :latest # resolver:disable Dependency/all
      mod 'puppetlabs-magic3', :latest # resolver:disable Validation/LatestVersion
      EOT
    end
    let(:puppetfile) { subject.parse(puppetfile_content) }

    it 'should add the DISABLE_PUPPET_DEPENDENCY_FLAG flag for Dependency/Puppet' do
      mod = get_module(puppetfile, 'puppetlabs-magic1')
      expect(mod.resolver_flags).to eq([PuppetfileResolver::Puppetfile::DISABLE_PUPPET_DEPENDENCY_FLAG])
    end

    it 'should add the DISABLE_ALL_DEPENDENCIES_FLAG flag for Dependency/All' do
      mod = get_module(puppetfile, 'puppetlabs-magic2')
      expect(mod.resolver_flags).to eq([PuppetfileResolver::Puppetfile::DISABLE_ALL_DEPENDENCIES_FLAG])
    end

    it 'should add the DISABLE_LATEST_VALIDATION_FLAG flag for Validation/LatestVersion' do
      mod = get_module(puppetfile, 'puppetlabs-magic3')
      expect(mod.resolver_flags).to eq([PuppetfileResolver::Puppetfile::DISABLE_LATEST_VALIDATION_FLAG])
    end
  end
end

RSpec.shared_examples "a puppetfile parser with invalid content" do
  let(:puppetfile_content) do
    <<-EOT
    forge 'https://fake-forge.puppetlabs.com/'

    mod 'puppetlabs-bad_version', 'b.c.d'

    mod 'bad_args',
      :gitx => 'git@github.com:puppetlabs/puppetlabs-git_ref.git'

    EOT
  end
  let(:puppetfile) { subject.parse(puppetfile_content) }

  def get_module(document, title)
    document.modules.find { |mod| mod.title == title }
  end

  it "should detect all of the invalid modules" do
    expect(puppetfile.modules.count).to eq(2)

    puppetfile.modules.each do |mod|
      expect(mod).to have_attributes(:module_type => PuppetfileResolver::Puppetfile::INVALID_MODULE)
      expect(mod.reason).to_not be_nil
    end
  end
end

RSpec.shared_examples "a puppetfile parser which raises" do
  [
    {
      name: 'with an unknown method',
      content: "mod_abc 'puppetlabs-forge_fixed_ver', '1.0.0'\n",
    },
    {
      name: 'with a bad forge module name',
      content: "mod 'bad\nname', '1.0.0'\n",
    },
    {
      name: 'with a syntax error',
      content: "} # syntax\n",
    },
    {
      name: 'with a syntax error in the middle of the line',
      content: "forge 'something' } # syntax\n",
    },
    {
      name: 'with an unknown require',
      content: "require 'not_loadable' # I am a load error\n",
    },
    {
      name: 'with a runtime error',
      content: "raise 'A Mock Runtime Error'\n",
    },
  ].each_with_index do |testcase, testcase_index|
    context "Given a puppetfile with #{testcase[:name]}" do
      let(:puppetfile_content) do
        # Add interesting things to the puppetfile content, so it's not just a single line
        "# Padding\n" * testcase_index + testcase[:content] + "# Padding\n" * testcase_index
      end
      let(:expected_error_line) { testcase_index }

      it "should raise a parsing error" do
        expect{ subject.parse(puppetfile_content) }.to raise_error(PuppetfileResolver::Puppetfile::Parser::ParserError)
      end

      it "should locate the error in the puppetfile" do
        begin
          subject.parse(puppetfile_content)
        rescue PuppetfileResolver::Puppetfile::Parser::ParserError => e
          expect(e.location.start_line).to eq(expected_error_line)
          expect(e.location.end_line).to eq(expected_error_line)
          # TODO: What about character position?
        end
      end
    end
  end
end

describe PuppetfileResolver::Puppetfile::Parser::R10KEval do
  let(:subject) { PuppetfileResolver::Puppetfile::Parser::R10KEval }

  it_behaves_like "a puppetfile parser with valid content"

  it_behaves_like 'a puppetfile parser with magic comments'

  it_behaves_like "a puppetfile parser with invalid content"

  it_behaves_like "a puppetfile parser which raises"
end
