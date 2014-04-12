#--
# SES Core Unit Tests
# ==============================================================================
# 
# Summary
# ------------------------------------------------------------------------------
#   This file provides unit tests for the SES Core script. These tests are
# provided in order to ensure that the SES Core script continues to function
# properly in the case of script updates or modifications from external sources
# (such as third-party scripts or scripters).
# 
#++
module SES::TestCases
  # ============================================================================
  # CoreScriptTest - Unit tests for the SES::Script class.
  # ============================================================================
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
  
  # ============================================================================
  # CoreRegisterTest - Unit tests for the SES::Register module.
  # ============================================================================
  class CoreRegisterTest < SES::Test::Spec
    describe 'Register' do SES::Register end
    let :script do SES::Script.new(:Example) end
    
    # Cleans the SES::Register entries and entries in the $imported global
    # variable so these tests do not contaminate either.
    def clean_register(key)
      subject.scripts.delete(key)
      $imported.delete("SES_#{key}".to_sym)
    end
    
    it '.enter adds the passed script to the register' do
      subject.enter(script)
      subject.scripts.values.must_include(script)
      clean_register(script.name)
    end
    
    it '.enter adds a default script to the register if none given' do
      subject.enter
      subject.scripts.keys.must_include(:Undefined_Script)
      clean_register(:Undefined_Script)
    end
    
    it '.enter adds formatted script information to $imported' do
      subject.enter(script)
      $imported.keys.must_include(:SES_Example)
      $imported[:SES_Example].must_equal 1.0
      clean_register(script.name)
    end
    
    it '.entries_for finds SES scripts given script name' do
      subject.entries_for(:Core).first.name.must_be_same_as :Core
    end
    
    it '.entries_for finds SES scripts given single author' do
      subject.enter(example_script = SES::Script.new(:Example, 1.0, :Solistra))
      subject.entries_for(:Solistra).must_include example_script
      clean_register(example_script.name)
    end
    
    it '.entries_for finds SES scripts with all given authors' do
      subject.enter(script)
      subject.entries_for(:Solistra, :Enelvon).must_include script
      clean_register(script.name)
    end
    
    it '.entries_for finds SES scripts given version number' do
      subject.enter(script)
      subject.entries_for(script.version).must_include script
      clean_register(script.name)
    end
    
    it '.include? returns expected values' do
      subject.include?(script.name).must_be_same_as false
      subject.enter(script)
      subject.include?(script.name).must_be_same_as true
      clean_register(script.name)
    end
    
    it '.require raises LoadError if requirement is not present' do
      begin
        subject.require({ :Example => 1.0 })
      rescue LoadError ; true else false end
    end
    
    it '.require raises LoadError if requirement is a low version' do
      subject.enter(script)
      begin
        subject.require({ :Example => 2.0 })
      rescue LoadError ; true else false end
      clean_register(script.name)
    end
    
    it '.require returns true if new requirements were met' do
      subject.enter(script)
      subject.require({ script.name => script.version }).must_be_same_as true
      clean_register(script.name)
    end
    
    it '.require returns false if no new requirements met' do
      subject.enter(script)
      subject.require({ script.name => script.version })
      subject.require({ script.name => script.version }).must_be_same_as false
      clean_register(script.name)
    end
  end
  
  # ============================================================================
  # CoreExtensionsTest - Unit tests for extensions to VX Ace data structures.
  # ============================================================================
  class CoreExtensionsTest < SES::Test::Spec
    describe 'Extensions' do SES::Extensions end
    let :event do MockEvent.new end
    
    # Provides a simple "mock" event for testing purposes.
    class MockEvent
      include SES::Extensions::Comments
      attr_reader :list
      
      def initialize
        @list = [
          RPG::EventCommand.new(108, 0, ['<test>']),
          RPG::EventCommand.new(408, 0, ['Second line.'])
        ]
      end
    end
    
    it 'provide appropriate methods' do
      subject::Notes.instance_methods.must_include(:scan_ses_notes)
      [:comments, :scan_ses_comments].each do |instance_method|
        subject::Comments.instance_methods.must_include(instance_method)
      end
      [:this, :event].each do |instance_method|
        subject::Interpreter.instance_methods.must_include(instance_method)
      end
    end
    
    it '::Notes#scan_ses_notes scans notes appropriately' do
      (tester = RPG::BaseItem.new).note = '<test>'
      capture_output do
        tester.scan_ses_notes(/<test>/ => 'puts "Success."')
      end.must_equal "Success.\n"
    end
    
    it '::Comments#comments returns an array of comments' do
      event.comments.must_equal ['<test>', 'Second line.']
    end
    
    it '::Comments#scan_ses_comments scans comments appropriately' do
      capture_output do
        event.scan_ses_comments(/<test>/ => 'puts "Success."')
      end.must_equal "Success.\n"
    end
    
    it '::Interpreter#event returns the given event id instance' do
      $game_map.stub(:events, {1 => event}) do
        Game_Interpreter.new.event(1).must_be_same_as event
      end
    end
    
    it '::Interpreter#event returns event for interpreter' do
      (interpreter = Game_Interpreter.new).setup([], 1)
      $game_map.stub(:events, 1 => event) do
        interpreter.event.must_be_same_as event
      end
    end
    
    it '::Interpreter#event returns interpreter when appropriate' do
      (interpreter = Game_Interpreter.new).event.must_be_same_as interpreter
    end
  end
end