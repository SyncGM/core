#--
# Core v2.0 by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides the basic foundation for all SES scripts written by
# Enelvon and Solistra. It provides necessary infrastructure and an assortment
# of utility methods and extensions to the defaults provided by RPG Maker VX
# Ace.
# 
# License
# -----------------------------------------------------------------------------
#   This script is made available under the terms of the MIT Expat license.
# View [this page](http://sesvxace.wordpress.com/license/) for more detailed
# information.
# 
# Installation
# -----------------------------------------------------------------------------
#   Place this script below Materials, but above Main and all other SES
# scripts.
# 
#++
module SES
  # ===========================================================================
  # Script
  # ===========================================================================
  # Provides metadata (name, author, and version) for scripts.
  class Script
    attr_reader :data
    
    # Provides simple formatting for script names -- spaces are replaced with
    # underscores and vice versa. Returns the formatted name as a symbol.
    def self.format(name)
      name = name.to_s
      (name.include?(' ') ? name.gsub(' ', '_') : name.gsub('_', ' ')).to_sym
    end
    
    # Creates a new Script instance with the passed metadata information and
    # generates a "get" method for the :name, :authors, and :version keys of
    # the @data hash.
    def initialize(name, version = 1.0, *authors)
      authors = [:Solistra, :Enelvon] if authors.empty?
      (@data = {
        :name    => self.class.format(name),
        :authors => authors.map! { |author| author.to_sym },
        :version => version.to_f
      }).keys.each { |i| self.class.send(:define_method, i) { @data[i] } }
    end
    
    # Provides a readable description of the stored metadata.
    def description
      "SES #{self.class.format(name)} (v#{version})"
    end
    alias :to_s :description
  end
  # ===========================================================================
  # Register
  # ===========================================================================
  # Maintains a record of installed scripts and performs verification for any
  # subsequent script requirements.
  module Register
    @errors = {
      :not_found => 'The script SES %s is required, but could not be found.',
      :version   => 'SES %s (v%.1f) is required, but you have %s.'
    }
    @required = Hash.new(0)
    @scripts  = {}
    
    # Defining reader methods and aliases for the Register.
    class << self
      attr_reader :scripts, :required
      alias       :entries  :scripts
    end
    
    # Enters the passed script into the Register and automatically generates an
    # entry into the $imported global variable.
    def self.enter(script = Script.new('Undefined Script'))
      @scripts[script.name] = script
      ($imported ||= {})["SES_#{script.name}".to_sym] = script.version
      @scripts
    end
    
    # Returns an array of Script instances with metadata which matches all of
    # the passed queries.
    # NOTE: script names must be passed as symbols in the proper format, not
    # strings.
    def self.entries_for(*queries)
      @scripts.values.select do |script|
        queries.all? do |query|
          script.data.values.include?(query) || script.authors.include?(query)
        end
      end
    end
    
    # Provides script requirements. This method raises a LoadError if the given
    # hash includes a script that has not been registered or a script with a
    # higher version number than the one currently registered. Returns true if
    # there were new requirements, false if all requirements were met.
    def self.require(scripts = {})
      copy = @required.dup
      scripts.each do |script, version|
        next if @required[script] >= version
        if @scripts[script].nil?
          raise(LoadError.new(@errors[:not_found] % Script.format(script)))
        elsif @scripts[script].version < version
          message = @errors[:version] % [ Script.format(script), version,
                                          @scripts[script] ]
          raise(LoadError.new(message))
        end
        @required[script] = version
      end
      @required != copy
    end
    
    # Convenience method for determining whether or not the Register has any
    # entries that match the passed queries.
    def self.include?(*queries)
      !entries_for(*queries).empty?
    end
  end
  # ===========================================================================
  # Extensions
  # ===========================================================================
  # Defines methods to be included in the base RPG data structures and other
  # classes defined by RPG Maker VX Ace's default scripts.
  module Extensions
    # =========================================================================
    # Notes
    # =========================================================================
    # Provides the scan_ses_notes method for objects with note boxes.
    module Notes
      # Scans note boxes with passed regular expressions and evaluates given
      # strings appropriately. Regular expressions are given as keys to tags,
      # while strings of interpretable Ruby code are given as values.
      def scan_ses_notes(tags = {})
        note.split(/[\r\n+]/).each do |line|
          tags.each { |regex, code| eval(code) if regex =~ line }
        end
      end
    end
    # =========================================================================
    # Comments
    # =========================================================================
    # Provides the comments and scan_ses_comments methods for use with events
    # and common events.
    module Comments
      # Returns an array of separated comment strings on the currently active
      # event page.
      def comments
        @list.select { |c| c.code == 108 || c.code == 408 }.map! do |comment|
          comment.parameters.first
        end
      end
      
      # Scans comments with passed regular expressions and evaluates given
      # strings appropriately. Regular expressions are given as keys to tags,
      # while strings of interpretable Ruby code are given as values.
      def scan_ses_comments(tags = {})
        comments.each do |comment|
          tags.each { |regex, code| eval(code) if regex =~ comment }
        end
      end
    end
    # =========================================================================
    # Interpreter
    # =========================================================================
    # Provides the event method for use with instances of the interpreter.
    module Interpreter
      # Returns the instance of Game_Event represented by the passed id value
      # (or the Game_Interpreter instance if the id value is 0).
      def event(id = @event_id)
        id > 0 ? $game_map.events[id] : self
      end
      alias :this :event
    end
  end
  
  # Record script metadata in the Register.
  Description = Script.new(:Core, 2.0, :Solistra)
  Register.enter(Description)
end
# =============================================================================
# Class
# =============================================================================
class Class
  # Aliased to automatically include the SES module into any class or module
  # defined within the SES module's namespace.
  alias :ses_class_new :new
  def new(*args, &block)
    include ::SES if ancestors.any? { |ancestor| ancestor.to_s[/^SES[^:{2}]/] }
    ses_class_new(*args, &block)
  end
end
# =============================================================================
# RPG
# =============================================================================
module RPG
  # Including the SES extensions for note boxes and comments into the default
  # RPG Maker VX Ace data structures that make use of them.
  { SES::Extensions::Notes    => [Map, BaseItem, Tileset],
    SES::Extensions::Comments => [Event::Page, CommonEvent]
  }.each do |extension, base_classes|
    base_classes.each { |base_class| base_class.send(:include, extension) }
  end
end
# =============================================================================
# Game_Event
# =============================================================================
class Game_Event < Game_Character
  include SES::Extensions::Comments
end
# =============================================================================
# Game_Interpreter
# =============================================================================
class Game_Interpreter
  include SES::Extensions::Comments
  include SES::Extensions::Interpreter
end