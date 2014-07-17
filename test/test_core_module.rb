module SES::TestCases
  module Core
    class ModuleTest < SES::Test::Spec
      describe 'Module' do Module end
      
      it '#alias_method automatically registers aliases' do
        class ::String
          alias_method :ses_core_test_reverse, :reverse
        end
        SES::MethodData.aliases.must_include String
        SES::MethodData.aliases[String][:reverse].must_include \
          :ses_core_test_reverse
        
        String.send(:undef_method, :ses_core_test_reverse)
        SES::MethodData.aliases.delete(String)
      end
    end
  end
end