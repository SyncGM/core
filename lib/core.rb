#--
# Core v2.3 by Solistra and Enelvon
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides the basic foundation for all SES scripts written by
# Enelvon and Solistra. It provides necessary infrastructure and an assortment
# of utility methods and extensions to the defaults provided by RPG Maker VX
# Ace. In addition, this script provides automatic registration of aliased and
# overwritten methods which may be accessed through the `SES::MethodData`
# module.
# 
# License
# -----------------------------------------------------------------------------
#   This script is made available under the terms of the MIT Expat license.
# View [this page](http://sesvxace.wordpress.com/license/)  or the included
# LICENSE file for more detailed information.
# 
# Installation
# -----------------------------------------------------------------------------
#   Place this script below Materials, but above Main and all other SES
# scripts.
# 
#++

# =============================================================================
# SES
# =============================================================================
# The top-level namespace for all SES scripts.
module SES
  # ===========================================================================
  # MethodData
  # ===========================================================================
  # Provides information regarding aliased and overwritten methods.
  module MethodData
    class << self
      # Hash of registered aliases. Keys are objects with aliased methods,
      # values are hashes representing the original method names and all known
      # aliases of them.
      # 
      # @return [Hash{Object => Hash{Symbol => Array<Symbol>}}]
      attr_reader :aliases
      
      # Hash of registered overwritten methods. Keys are objects with methods
      # that have been overwritten, values are arrays of overwritten method
      # names.
      # 
      # @return [Hash{Object => Array<Symbol>}]
      attr_reader :overwrites
    end
    
    @aliases    = {}
    @overwrites = {}
    
    # Performs registration of method aliases.
    # 
    # @todo lib/core.rb: Currently, defining an alias in a singleton class
    #   registers the singleton class itself as the object where the alias was
    #   defined rather than the desired constant value.
    # 
    # @note This method ignores aliases generated via stubbed objects defined
    #   with the SES Test Case framework.
    # 
    # @param object [Object] the class or module where an alias was registered
    # @param name [Symbol] the aliased method name
    # @param method [Symbol] the original method name
    # @return [Boolean] `true` if the alias was added to the registry, `false`
    #   otherwise
    def self.register_alias(object, name, method)
      return false if [name, method].any? { |m| m =~ /^ses_testcase_stubbed_/ }
      @aliases[object]         ||= {}
      @aliases[object][method] ||= []
      unless @aliases[object][method].include?(name)
        @aliases[object][method].push(name)
        return true
      end
      false
    end
    
    # Performs registration of method overwrites.
    # 
    # @param object [Object] the class or module where the named method was
    #   overwritten
    # @param name [Symbol] the name of the overwritten method
    # @return [Boolean] `true` if the overwrite was added to the registry,
    #   `false` otherwise
    def self.register_overwrite(object, name)
      @overwrites[object] ||= []
      unless @overwrites[object].include?(name)
        @overwrites[object].push(name)
        return true
      end
      false
    end
    # =========================================================================
    # Overwrites
    # =========================================================================
    module Overwrites
      # Instance method analogous to a new keyword -- functions in the same way
      # as `public`, `protected`, and `private`. If no method names are given
      # to this method, the next method defined is automatically considered
      # overwritten -- otherwise, all of the given method names are registered
      # as overwritten.
      # 
      # @param names [Array<Symbol>] a list of method names as Symbols that are
      #   being overwritten
      # @raise [NoMethodError] if any of the given overwrites did not exist in
      #   the base class
      # @return [void]
      def overwrites(*names)
        if names.empty?
          @_overwrite = true
        else
          names.each do |name|
            unless instance_methods.include?(name) || respond_to?(name)
              raise NoMethodError, "No `#{name}` method to overwrite"
            end
            SES::MethodData.register_overwrite(self, name)
          end
        end
        return nil
      end
      alias_method :overwrite, :overwrites
      
      # @private
      # Registers the method via {SES::MethodData.register_overwrite} if the
      # {#overwrite} pseudo-keyword was placed directly before its definition.
      # 
      # @param name [Symbol] the method which was added
      # @return [void]
      def method_added(name)
        return super unless @_overwrite
        SES::MethodData.register_overwrite(self, name)
        @_overwrite = nil
        super
      end
      
      # @private
      # Registers the singleton method via {SES::MethodData.register_overwrite}
      # if the {#overwrite} pseudo-keyword was placed directly before its
      # definition.
      # 
      # @param name [Symbol] the singleton method which was added
      # @return [void]
      def singleton_method_added(name)
        return super unless @_overwrite
        SES::MethodData.register_overwrite(self, name)
        @_overwrite = nil
        super
      end
      
      # Extend all objects with the functionality of this module.
      Object.extend(self)
    end
  end
end
# =============================================================================
# Module
# =============================================================================
# The superclass of {Class}; essentially a class without instantiation support.
class Module
  # Aliased to automatically register methods aliased via `alias_method` with
  # the {SES::MethodData.register_alias} method.
  # 
  # @see {#alias_method}
  alias_method :ses_core_module_alias_method, :alias_method
  
  # Performs method aliasing in a more predictable way than `alias`.
  # 
  # @param name [Symbol] the aliased method name
  # @param method [Symbol] the original method being aliased
  # @return [self]
  def alias_method(name, method, *args, &block)
    SES::MethodData.register_alias(self, name, method)
    ses_core_module_alias_method(name, method, *args, &block)
  end
end
# =============================================================================
# SES
# =============================================================================
# The top-level namespace for all SES scripts.
module SES
  # ===========================================================================
  # Script
  # ===========================================================================
  # Provides metadata (name, author, and version) for scripts.
  class Script
    # The underlying hash of script information. Contains `:name`, `:authors`,
    # and `:version` keys with appropriate values.
    # 
    # @return [Hash{Symbol => Object}]
    attr_reader :data
    
    # Provides simple formatting for script names -- spaces are replaced with
    # underscores and vice versa. Returns the formatted name as a symbol.
    # 
    # @param name [#to_s] the name to format
    # @return [Symbol] the properly formatted name
    def self.format(name)
      name = name.to_s
      (name.include?(' ') ? name.gsub(' ', '_') : name.gsub('_', ' ')).to_sym
    end
    
    # Creates a new Script instance with the passed metadata information and
    # generates a reader method for the `:name`, `:authors`, and `:version`
    # keys of the `@data` hash.
    # 
    # @param name [String, Symbol] the name of the script
    # @param version [Float] the version number of the script
    # @param authors [Array<Symbol>] a list of script authors
    # @return [Script] a new instance of Script
    def initialize(name, version = 1.0, *authors)
      authors = [:Solistra, :Enelvon] if authors.empty?
      (@data = {
        :name    => self.class.format(name),
        :authors => authors.map! { |author| author.to_sym },
        :version => version.to_f
      }).keys.each { |i| self.class.send(:define_method, i) { @data[i] } }
    end
    
    # Provides a readable description of the stored metadata.
    # 
    # @return [String] a properly formatted description
    def description
      "SES #{self.class.format(name)} (v#{version})"
    end
    alias_method :to_s, :description
  end
  # ===========================================================================
  # Register
  # ===========================================================================
  # Maintains a record of installed scripts and performs verification for any
  # subsequent script requirements.
  module Register
    class << self
      # Hash of {Script} objects that have been entered into the {Register}. 
      # Keys are Symbols representing script names, values are {Script}
      # objects.
      # 
      # @return [Hash{Symbol => Script}]
      attr_reader :scripts
      
      # Hash of {Script} objects which have been required by other SES scripts.
      # Keys are Symbols representing script names, values are minimum required
      # script versions.
      # 
      # @return [Hash{Symbol => Float}]
      attr_reader :required
      alias_method :entries, :scripts
    end
    
    @errors = {
      :not_found => 'The script SES %s is required, but could not be found.',
      :version   => 'SES %s (v%.1f) is required, but you have %s.'
    }
    @required = Hash.new(0)
    @scripts  = {}
    
    # Enters the passed script into the {Register} and automatically generates
    # an entry into the `$imported` global variable.
    # 
    # @param script [Script] the {Script} object to enter
    # @raise [ArgumentError] if the given script is not an instance of {Script}
    # @return [Hash{Symbol => Script}] hash of all entered {Script} objects
    def self.enter(script)
      unless script.instance_of?(Script)
        raise ArgumentError, "#{script.inspect} is not a valid Script instance"
      end
      @scripts[script.name] = script
      ($imported ||= {})["SES_#{script.name}".to_sym] = script.version
      @scripts
    end
    
    # Returns an array of {Script} instances with metadata which matches all of
    # the passed queries.
    # 
    # @note {Script} names must be passed as symbols in the proper format, not
    #   strings.
    # 
    # @param queries [Array] a list of queries to perform
    # @return [Array<Script>] an array of {Script} objects matching all of the
    #   given queries
    def self.entries_for(*queries)
      @scripts.values.select do |script|
        queries.all? do |query|
          script.data.values.include?(query) || script.authors.include?(query)
        end
      end
    end
    
    # Provides verification and registration of script requirements.
    # 
    # @param scripts [Hash{Symbol => Float}] hash of scripts to require. Keys
    #   are Symbols representing script names, values are minumum required 
    #   script versions
    # @raise [LoadError] if the given hash includes a {Script} that has not
    #   been registered or a {Script} with a higher version number than the one
    #   currently registered
    # @return [Boolean] `true` if new requirements were registered, `false` if
    #   all requirements were already met
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
    
    # Convenience method for determining whether or not the {Register} has any
    # entries that match the passed queries.
    # 
    # @param queries [Array] a list of queries to perform
    # @return [Boolean] `true` if any registered {Script}s match the given
    #   queries, `false` otherwise
    # 
    # @see #entries_for
    def self.include?(*queries)
      !entries_for(*queries).empty?
    end
  end
  # ===========================================================================
  # Extensions
  # ===========================================================================
  # Defines methods to be included in the base `RPG` data structures and other
  # classes defined by RPG Maker VX Ace's default scripts.
  module Extensions
    # =========================================================================
    # Notes
    # =========================================================================
    # Provides the {#scan_ses_notes} method for objects with note boxes.
    module Notes
      # Scans note boxes with passed regular expressions and evaluates given
      # values appropriately. Regular expressions are given as keys to tags,
      # while strings, Procs, or Lambdas of interpretable Ruby code are given
      # as values. Procs and Lambdas will be called on the current object via
      # `#instance_exec`.
      # 
      # @param tags [Hash{Regexp => String, Proc}] hash of tags to scan; keys
      #   are regular expressions, values are the code to evaluate if the given
      #   regular expression is matched
      # @return [void]
      # 
      # @see Comments#scan_ses_comments
      def scan_ses_notes(tags = {})
        note.split(/[\r\n+]/).each do |line|
          tags.each do |regex, code|
            if line[regex]
              if code.is_a?(String)
                eval(code)
              else instance_exec(*$~[1...$~.size], &code) end
            end
          end
        end
      end
    end
    # =========================================================================
    # Comments
    # =========================================================================
    # Provides the {#comments} and {#scan_ses_comments} methods for use with
    # events and common events.
    module Comments
      # Returns an array of separated comment strings on the currently active
      # event page.
      # 
      # @return [Array<String>] an array of comment strings
      def comments
        @list.select { |c| c.code == 108 || c.code == 408 }.map! do |comment|
          comment.parameters.first
        end
      end
      
      # Scans comments with passed regular expressions and evaluates given
      # values appropriately. Regular expressions are given as keys to tags,
      # while strings, Procs, or Lambdas of interpretable Ruby code are given
      # as values. Procs and Lambdas will be called on the current object via
      # `#instance_exec`.
      # 
      # @param tags [Hash{Regexp => String, Proc}] hash of tags to scan; keys
      #   are regular expressions, values are the code to evaluate if the given
      #   regular expression is matched
      # @return [void]
      # 
      # @see Notes#scan_ses_notes
      def scan_ses_comments(tags = {})
        comments.each do |comment|
          tags.each do |regex, code|
            if comment[regex]
              if code.is_a?(String)
                eval(code)
              else instance_exec(*$~[1...$~.size], &code) end
            end
          end
        end
      end
    end
    # =========================================================================
    # Interpreter
    # =========================================================================
    # Provides the {#event} method for use with instances of the interpreter.
    module Interpreter
      # Returns the instance of `Game_Event` represented by the passed ID value
      # (or the `Game_Interpreter` instance if the ID value is 0).
      # 
      # @param id [Numeric] the event ID used to obtain the appropriate
      #   `Game_Event` or `Game_Interpreter` instance
      # @return [Game_Event, Game_Interpreter] the desired `Game_Event` or
      #   `Game_Interpreter` instance
      def event(id = @event_id)
        id > 0 ? $game_map.events[id] : self
      end
      alias_method :this, :event
    end
  end
  
  # Script metadata as a {Script} instance.
  Description = Script.new(:Core, 2.3)
  Register.enter(Description)
end
# =============================================================================
# Class
# =============================================================================
# All Ruby classes are instances of this class.
class Class
  # Aliased to automatically include the {SES} module into any class or module
  # defined within the {SES} module's namespace.
  # 
  # @see {#new}
  alias_method :ses_core_class_new, :new
  
  # Instantiates a new instance of `self`.
  # 
  # @return [self]
  def new(*args, &block)
    include ::SES if ancestors.any? { |ancestor| ancestor.to_s[/^SES[^:{2}]/] }
    ses_core_class_new(*args, &block)
  end
end
# =============================================================================
# RPG
# =============================================================================
# Provides the basic data structures used by the RPG Maker VX Ace editor.
module RPG
  # Including the {SES::Extensions} for notes and comments into the default RPG
  # Maker VX Ace data structures that make use of them.
  { SES::Extensions::Notes    => [Map, BaseItem, Tileset],
    SES::Extensions::Comments => [Event::Page, CommonEvent]
  }.each do |extension, base_classes|
    base_classes.each { |base_class| base_class.send(:include, extension) }
  end
end
# =============================================================================
# Game_Event
# =============================================================================
# Handles events. Functions include event page switching via condition
# determinants and running parallel process events. Used within the `Game_Map`
# class.
class Game_Event < Game_Character
  include SES::Extensions::Comments
end
# =============================================================================
# Game_Interpreter
# =============================================================================
# An interpreter for executing event commands. This class is used within the
# `Game_Map`, `Game_Troop`, and {Game_Event} classes.
class Game_Interpreter
  include SES::Extensions::Comments
  include SES::Extensions::Interpreter
end