module SES::TestCases
  module Core
    class OverwritesTest < SES::Test::Spec
      describe 'Overwrites' do SES::MethodData::Overwrites end
      
      # Provides a simple mock object for method overwrite testing.
      class MockObject
        def overwrite_this() end
      end
      
      it '#overwrites registers the given overwritten methods' do
        class MockObject
          overwrites :overwrite_this
        end
        SES::MethodData.overwrites.must_include MockObject
        SES::MethodData.overwrites[MockObject].must_include :overwrite_this
        
        SES::MethodData.overwrites.delete(MockObject)
      end
      
      it '#overwrites raises NoMethodError if method did not exist' do
        class MockObject
          begin
            overwrites :no_method
          rescue NoMethodError ; true else false
          end
        end
      end
      
      it '#overwrites without arguments registers the next method' do
        class MockObject
          overwrites
          def overwrite_this() end
          def overwrite_that() end
        end
        SES::MethodData.overwrites.must_include(MockObject)
        SES::MethodData.overwrites[MockObject].must_include :overwrite_this
        SES::MethodData.overwrites[MockObject].cannot_include :overwrite_that
        
        SES::MethodData.overwrites.delete(MockObject)
      end
    end
  end
end
