module SES::TestCases
  module Core
    class MethodDataTest < SES::Test::Spec
      describe 'MethodData' do SES::MethodData end
      
      def clean(type, key)
        subject.send(type).delete(key)
      end
      
      it '.register_alias registers aliases appropriately' do
        subject.register_alias(self, :test_clean, :clean)
        subject.aliases.must_include self
        subject.aliases[self][:clean].must_include :test_clean
        
        clean(:aliases, self)
      end
      
      it '.register_alias returns true with new alias' do
        subject.register_alias(self, :test_clean, :clean).must_equal true
        
        clean(:aliases, self)
      end
      
      it '.register_alias returns false without new alias' do
        subject.register_alias(self, :test_clean, :clean)
        subject.register_alias(self, :test_clean, :clean).must_equal false
        
        clean(:aliases, self)
      end
      
      it '.register_alias ignores Test Case stubbed object aliases' do
        object = Object.new
        object.stub(:object_id, 0) { subject.aliases.cannot_include object }
      end
      
      it '.register_overwrite registers overwrites appropriately' do
        subject.register_overwrite(self, :clean)
        subject.overwrites.must_include self
        subject.overwrites[self].must_include :clean
        
        clean(:overwrites, self)
      end
      
      it '.register_overwrite returns true with new overwrite' do
        subject.register_overwrite(self, :clean).must_equal true
        
        clean(:overwrites, self)
      end
      
      it '.register_overwrite returns false without new overwrite' do
        subject.register_overwrite(self, :clean)
        subject.register_overwrite(self, :clean).must_equal false
        
        clean(:overwrites, self)
      end
    end
  end
end
