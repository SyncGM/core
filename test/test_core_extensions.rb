module SES::TestCases
  # ===========================================================================
  # CoreExtensionsTest - Unit tests for extensions to VX Ace data structures.
  # ===========================================================================
  class CoreExtensionsTest < SES::Test::Spec
    describe 'Extensions' do SES::Extensions end
    let :event do MockEvent.new end
    let :item  do MockItem.new  end
    
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
    
    # Provides a simple "mock" item for testing purposes.
    class MockItem
      include SES::Extensions::Notes
      attr_reader :note
      
      def initialize
        @note = '<test>'
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
    
    it '::Notes#scan_ses_notes scans notes given a String' do
      capture_output do
        item.scan_ses_notes(/<test>/ => 'puts "Success."')
      end.must_equal "Success.\n"
    end
    
    it '::Notes#scan_ses_notes scans notes given a Proc' do
      capture_output do
        item.scan_ses_notes(/<test>/ => -> { puts 'Success.' })
      end.must_equal "Success.\n"
    end
    
    it '::Comments#comments returns an array of comments' do
      event.comments.must_equal ['<test>', 'Second line.']
    end
    
    it '::Comments#scan_ses_comments scans comments given a String' do
      capture_output do
        event.scan_ses_comments(/<test>/ => 'puts "Success."')
      end.must_equal "Success.\n"
    end
    
    it '::Comments#scan_ses_comments scans comments given a Proc' do
      capture_output do
        event.scan_ses_comments(/<test>/ => -> { puts 'Success.' })
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