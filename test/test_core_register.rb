module SES::TestCases
  module Core
    class RegisterTest < SES::Test::Spec
      describe 'Register' do SES::Register end
      let :script do SES::Script.new(:Example) end
      
      # Cleans the SES::Register entries and entries in the $imported global
      # variable so these tests do not contaminate either.
      def clean(key)
        subject.scripts.delete(key)
        $imported.delete("SES_#{key}".to_sym)
      end
      
      it '.enter adds the passed script to the register' do
        subject.enter(script)
        subject.scripts.values.must_include(script)
        
        clean(script.name)
      end
      
      it '.enter adds formatted script information to $imported' do
        subject.enter(script)
        $imported.keys.must_include(:SES_Example)
        $imported[:SES_Example].must_equal 1.0
        
        clean(script.name)
      end
      
      it '.entries_for finds SES scripts given script name' do
        subject.entries_for(:Core).first.name.must_be_same_as :Core
      end
      
      it '.entries_for finds SES scripts given single author' do
        subject.enter(example = SES::Script.new(:Example, 1.0, :Solistra))
        subject.entries_for(:Solistra).must_include example
        
        clean(example.name)
      end
      
      it '.entries_for finds SES scripts with all given authors' do
        subject.enter(script)
        subject.entries_for(:Solistra, :Enelvon).must_include script
        
        clean(script.name)
      end
      
      it '.entries_for finds SES scripts given version number' do
        subject.enter(script)
        subject.entries_for(script.version).must_include script
        
        clean(script.name)
      end
      
      it '.include? returns expected values' do
        subject.include?(script.name).must_be_same_as false
        subject.enter(script)
        subject.include?(script.name).must_be_same_as true
        
        clean(script.name)
      end
      
      it '.require raises LoadError if requirement is not present' do
        must_raise(LoadError) do
          subject.require({ :Example => 1.0 })
        end
      end
      
      it '.require raises LoadError if requirement is a low version' do
        subject.enter(script)
        
        must_raise(LoadError) do
          subject.require({ :Example => 2.0 })
        end
        
        clean(script.name)
      end
      
      it '.require returns true if new requirements were met' do
        subject.enter(script)
        subject.require({ script.name => script.version }).must_be_same_as true
        
        clean(script.name)
      end
      
      it '.require returns false if no new requirements met' do
        subject.enter(script)
        subject.require({ script.name => script.version })
        subject.require({ script.name => script.version }).must_be_same_as \
          false
        
        clean(script.name)
      end
    end
  end
end
