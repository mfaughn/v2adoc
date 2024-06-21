require 'json'
require 'singleton'

module V2AD
  class V2
    include Singleton
    attr_reader :sections, :datatypes, :segments, :segment_defs, :message_types, :message_structures, :events, :data_elements, :fields, :tables, :ack_chors, :messages, :seg_seqs, :texts
    def initialize
      reset
      # puts self.instance_variables
      # puts '_______'
      # puts self.class.instance_methods(false)
      # raise
    end
    
    def reset
      @sections           = {}
      @datatypes          = {}
      @segment_defs       = {}
      @segments           = []
      @seg_seqs           = []
      @message_types      = {}
      @events             = {}
      @data_elements      = {}
      @message_structures = {}
      @fields             = {}
      @tables             = {}
      @ack_chors          = []
      @messages           = []
      @texts              = []
      V2AD.reset_general_ack
    end
  end
  
  module_function
  
  def v2
    V2.instance
  end
  
  def reset
    v2.reset
  end
  
  def add_table(t, source) # FIXME what is this and what is it for?
    v2.tables[t] ||= []
    v2.tables[t] << source
  end

  # For now we are just returning strings.  FIXME after we check message structures we can start to return actual message objects
  def get_message_codes(codes_str)
    codes_str.split(/\s*or\s*/)
  end

  def empty_asciidoc?(asciidoc)
    ll = asciidoc.lines.map do |l|
      l.chomp.strip[0]
    end
    ll.shift if ll.first.to_s.strip =~ /^=+/
    ll.compact.empty?
    # ret = ll.compact.empty?
    # unless ret
    #   puts "NOT SKIPPING"
    #   pp asciidoc.lines
    # end
    # ret
  end
end
