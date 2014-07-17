module SES::TestCases
  module Core
    class CoreScriptTest < SES::Test::Spec
      describe 'Script' do SES::Script end
      
      it 'initializes with given name' do
        subject.new(:Example).name.must_be_same_as :Example
      end
      
      it 'defines #authors, #name, and #version methods' do
        script = subject.new(:Example)
        [:authors, :name, :version].each do |instance_method|
          script.must_respond_to(instance_method)
        end
      end
      
      it '#authors, #name, and #version return expected values' do
        script = subject.new(:Example)
        [:authors, :name, :version].each do |ivar|
          expectation = script.instance_variable_get('@data')[ivar]
          script.send(ivar).must_equal expectation
        end
      end
      
      it 'initializes with default author and version' do
        script = subject.new(:Example)
        script.authors.must_equal [:Solistra, :Enelvon]
        script.version.must_equal 1.0
      end
      
      it 'initializes with given version and authors' do
        script = subject.new(:Example, 0.1, :Nobody)
        script.authors.must_equal [:Nobody]
        script.version.must_equal 0.1
      end
      
      it '.format appropriately formats symbols' do
        subject.format(:Example_Script).must_be_same_as :"Example Script"
      end
      
      it '.format appropriately formats descriptive symbols' do
        subject.format(:"Example Script").must_be_same_as :Example_Script
      end
      
      it '.format appropriately formats descriptive strings' do
        subject.format('Example Script').must_be_same_as :Example_Script
      end
    end
  end
end
