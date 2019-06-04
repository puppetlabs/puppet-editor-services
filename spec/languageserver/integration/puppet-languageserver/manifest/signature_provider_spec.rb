require 'spec_helper'

def pretty_string(value)
  value.nil? ? 'nil' : value.to_s
end

describe 'signature_provider' do
  let(:subject) { PuppetLanguageServer::Manifest::SignatureProvider }

  before(:all) do
    wait_for_puppet_loading
  end

  before(:each) do
    # Prepopulate the Object Cache with workspace objects
    # Functions
    list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
    list << PuppetLanguageServer::Sidecar::Protocol::PuppetFunction.new.from_h!({
      'key'              => 'func_two_param',
      'doc'              => 'documentation for func_two_param',
      'function_version' => 4,
      'signatures'       => [
        {
          'key'          => 'func_two_param(Any $p1)',
          'doc'          => 'first func_two_param signature',
          'return_types' => ['Any'],
          'parameters'   => [
            { 'name' => 'p1', 'types' => ['Any'], 'doc' => 'p1 documentation' },
          ]
        },
        {
          'key'          => 'func_two_param(Any $p1, Any $p2)',
          'doc'          => 'second func_two_param signature',
          'return_types' => ['Any'],
          'parameters'   => [
            { 'name' => 'p1', 'types' => ['Any'], 'doc' => 'p1 documentation' },
            { 'name' => 'p2', 'types' => ['Any'], 'doc' => 'p2 documentation' },
          ]
        },
      ]
    })
    list << PuppetLanguageServer::Sidecar::Protocol::PuppetFunction.new.from_h!({
      'key'              => 'func_three_param',
      'doc'              => 'documentation for func_three_param',
      'function_version' => 4,
      'signatures'       => [
        {
          'key'          => 'func_three_param(Any $p1, Any $p2, Any $p3)',
          'doc'          => 'first func_three_param signature',
          'return_types' => ['Any'],
          'parameters'   => [
            { 'name' => 'p1', 'types' => ['Any'], 'doc' => 'p1 documentation' },
            { 'name' => 'p2', 'types' => ['Any'], 'doc' => 'p2 documentation' },
            { 'name' => 'p3', 'types' => ['Any'], 'doc' => 'p3 documentation' }
          ]
        },
      ]
    })
    PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!(list, :function, :workspace)
  end

  after(:each) do
    # Clear out the Object Cache of workspace objects
    PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :function, :workspace)
  end

  describe '#signature_help' do
    context "Given a simple valid manifest with a function with three parameters" do
      let(:content) { "#something\nfunc_three_param( $param1  ,  $param2  ,\'param3\') \n#somethingelse" }

      [
        { :name => 'after the start bracket',     :character => 17, :activeParameter => 0 },
        { :name => 'within the first parameter',  :character => 20, :activeParameter => 0 },
        { :name => 'before first comma',          :character => 26, :activeParameter => 0 },
        { :name => 'after first comma',           :character => 28, :activeParameter => 1 },
        { :name => 'within the second parameter', :character => 34, :activeParameter => 1 },
        { :name => 'after second parameter',      :character => 37, :activeParameter => 1 },
        { :name => 'after second comma',          :character => 40, :activeParameter => 2 },
        { :name => 'within the third parameter',  :character => 44, :activeParameter => 2 },
        { :name => 'before the end bracket',      :character => 48, :activeParameter => 2 },
      ].each do |testcase|
        describe "When the cursor is #{testcase[:name]}" do
          it "should use the first signature" do
            result = subject.signature_help(content, 1, testcase[:character], { :tasks_mode => true})

            expect(result.activeSignature).to eq(0)
          end

          it "should have an active parameter of #{pretty_string(testcase[:activeParameter])}" do
            result = subject.signature_help(content, 1, testcase[:character], { :tasks_mode => true})

            expect(result.activeParameter).to eq(testcase[:activeParameter])
          end
        end
      end
    end

    context "Given a simple valid manifest with a function with two parameters" do
      context "When supplying only one parameter" do
        let(:content) { "#something\nfunc_two_param( $param1 ) \n#somethingelse" }

        [
          { :name => 'middle of first parameter',  :character => 20, :activeParameter => 0, :activeSignature => 0 },
        ].each do |testcase|
          describe "When the cursor is in #{testcase[:name]}" do
            it "should have an active signature of #{pretty_string(testcase[:activeSignature])}" do
              result = subject.signature_help(content, 1, testcase[:character], { :tasks_mode => true})

              expect(result.activeSignature).to eq(testcase[:activeSignature])
            end

            it "should have an active parameter of #{pretty_string(testcase[:activeParameter])}" do
              result = subject.signature_help(content, 1, testcase[:character], { :tasks_mode => true})

              expect(result.activeParameter).to eq(testcase[:activeParameter])
            end
          end
        end
      end

      context "When supplying two parameters" do
        let(:content) { "#something\nfunc_two_param( $param1 , $param2 ) \n#somethingelse" }

        [
          { :name => 'within the first parameter',   :character => 20, :activeParameter => 0, :activeSignature => 1 },
          { :name => 'within the second parameter',  :character => 29, :activeParameter => 1, :activeSignature => 1 },
        ].each do |testcase|
          describe "When the cursor is in #{testcase[:name]}" do
            it "should have an active signature of #{pretty_string(testcase[:activeSignature])}" do
              result = subject.signature_help(content, 1, testcase[:character], { :tasks_mode => true})

              expect(result.activeSignature).to eq(testcase[:activeSignature])
            end

            it "should have an active parameter of #{pretty_string(testcase[:activeParameter])}" do
              result = subject.signature_help(content, 1, testcase[:character], { :tasks_mode => true})

              expect(result.activeParameter).to eq(testcase[:activeParameter])
            end
          end
        end
      end
    end

    context "Given a manifest part way through editing at the end" do
      let(:content) { 'func_three_param( $param1  ,  ) ' }

      [
        { :name => 'after the start bracket',    :character => 17, :activeParameter => 0 },
        { :name => 'within the first parameter', :character => 20, :activeParameter => 0 },
        { :name => 'before first comma',         :character => 26, :activeParameter => 0 },
        { :name => 'after first comma',          :character => 28, :activeParameter => 1 },
        { :name => 'before the end bracket',     :character => 30, :activeParameter => 1 },
      ].each do |testcase|
        describe "When the cursor is #{testcase[:name]}" do
          it "should use the first signature" do
            result = subject.signature_help(content, 0, testcase[:character], { :tasks_mode => true})

            expect(result.activeSignature).to eq(0)
          end

          it "should have an active parameter of #{pretty_string(testcase[:activeParameter])}" do
            result = subject.signature_help(content, 0, testcase[:character], { :tasks_mode => true})

            expect(result.activeParameter).to eq(testcase[:activeParameter])
          end
        end
      end
    end

    context "Given a manifest with nested function calls, across multiple lines" do
      let(:content) { "func_three_param( $param1  ,\n  func_two_param( $nest1 , $nest2) ,\n  $param3\n) " }

      describe "Within the first function" do
        [
          { :name => 'after the start bracket',    :line => 0, :character => 17, :activeParameter => 0, :activeSignature => 0 },
          { :name => 'within the first parameter', :line => 0, :character => 22, :activeParameter => 0, :activeSignature => 0 },
          { :name => 'before first comma',         :line => 0, :character => 26, :activeParameter => 0, :activeSignature => 0 },
          { :name => 'after first comma',          :line => 0, :character => 28, :activeParameter => 1, :activeSignature => 0 },
          { :name => 'before second comma',        :line => 1, :character => 35, :activeParameter => 1, :activeSignature => 0 },
          { :name => 'after second comma',         :line => 1, :character => 36, :activeParameter => 2, :activeSignature => 0 },
          { :name => 'within the third parameter', :line => 2, :character => 4, :activeParameter => 2, :activeSignature => 0 },
          { :name => 'before the end bracket',     :line => 3, :character => 0, :activeParameter => 2, :activeSignature => 0 },
        ].each do |testcase|
          describe "When the cursor is #{testcase[:name]}" do
            it "should return signatures for the first function" do
              result = subject.signature_help(content, testcase[:line], testcase[:character], { :tasks_mode => true})

              expect(result.signatures.count).to be > 0
              expect(result.signatures[0].documentation).to match(/func_three_param/)
            end

            it "should have an active signature of #{pretty_string(testcase[:activeSignature])}" do
              result = subject.signature_help(content, testcase[:line], testcase[:character], { :tasks_mode => true})

              expect(result.activeSignature).to eq(testcase[:activeSignature])
            end

            it "should have an active parameter of #{pretty_string(testcase[:activeParameter])}" do
              result = subject.signature_help(content, testcase[:line], testcase[:character], { :tasks_mode => true})

              expect(result.activeParameter).to eq(testcase[:activeParameter])
            end
          end
        end
      end

      describe "Within the second function" do
        [
          { :name => 'after the start bracket',     :line => 1, :character => 17, :activeParameter => 0,   :activeSignature => 1 },
          { :name => 'within the first parameter',  :line => 1, :character => 19, :activeParameter => 0,   :activeSignature => 1 },
          { :name => 'before first comma',          :line => 1, :character => 24, :activeParameter => 0,   :activeSignature => 1 },
          { :name => 'after first comma',           :line => 1, :character => 26, :activeParameter => 1,   :activeSignature => 1 },
          { :name => 'within the second parameter', :line => 1, :character => 30, :activeParameter => 1,   :activeSignature => 1 },
          { :name => 'before the end bracket',      :line => 1, :character => 33, :activeParameter => 1,   :activeSignature => 1 },
        ].each do |testcase|
          describe "When the cursor is #{testcase[:name]}" do
            it "should return signatures for the second function" do
              result = subject.signature_help(content, testcase[:line], testcase[:character], { :tasks_mode => true})

              expect(result.signatures.count).to be > 0
              expect(result.signatures[0].documentation).to match(/func_two_param/)
            end

            it "should have an active signature of #{pretty_string(testcase[:activeSignature])}" do
              result = subject.signature_help(content, testcase[:line], testcase[:character], { :tasks_mode => true})

              expect(result.activeSignature).to eq(testcase[:activeSignature])
            end

            it "should have an active parameter of #{pretty_string(testcase[:activeParameter])}" do
              result = subject.signature_help(content, testcase[:line], testcase[:character], { :tasks_mode => true})

              expect(result.activeParameter).to eq(testcase[:activeParameter])
            end
          end
        end
      end
    end

    context "Given an invalid manifest" do
      [
        { :name => 'an empty first parameter', :manifest => 'func_three_param(  , $param1  ) ' },
        { :name => 'a missing middle parameter', :manifest => 'func_three_param($param1  , , ) ' },
      ].each do |testcase|
        describe "When the manifest has #{testcase[:name]}" do
          it "should raise a runtime error" do
            expect {subject.signature_help(testcase[:manifest], 0, 18, { :tasks_mode => true}) }.to raise_error(RuntimeError)
          end
        end
      end
    end

    context 'Given an invalid character location' do
      describe 'With a single function in the manifest' do
        let(:content) { "#something\nfunc_three_param( $param1  ,  $param2  ,\'param3\') \n#somethingelse" }

        [
          { :name => 'on function name',         :character => 3 },
          { :name => 'before the start bracket', :character => 16 },
          { :name => 'after the end bracket',    :character => 49 },
        ].each do |testcase|
          describe "When the cursor is #{testcase[:name]}" do
            it 'should raise a runtime error' do
              expect {subject.signature_help(content, 1, testcase[:character], { :tasks_mode => true}) }.to raise_error(RuntimeError)
            end
          end
        end
      end

      describe 'With a nested function in the manifest' do
        let(:content) { 'func_three_param( $param1  , func_two_param( $nest1 , $nest2) , $param3)' }

        [
          { :name => 'on outer function name',  :character => 8 },
          { :name => 'on nested function name', :character => 36 },
        ].each do |testcase|
          describe "When the cursor is #{testcase[:name]}" do
            it 'should raise a runtime error' do
              expect {subject.signature_help(content, 0, testcase[:character], { :tasks_mode => true}) }.to raise_error(RuntimeError)
            end
          end
        end
      end
    end
  end
end
