# require_relative 'utils'
require 'json'
require 'singleton'
# require 'sequel'

# DB = Sequel.sqlite # in-memory DB
# Sequel::Model.plugin :json_serializer
#
# dbtables = [
#   :sections => [[String, :adoc], [String, :number]],
#   :events   => [[String, :adoc_source], [String, :text], [String, :code], [String, :status]],
#
# ]
#
# DB.create_table :sections do
#   primary_key :id
#   String :adoc
#   String :number
# end
#
# DB.create_table
# end

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
  
  def ack_type
    find_or_create_message_type('ACK', section)
  end
  
  def create_ack_message(for_msg)
    # for_msg is the message that this ack is for
    raise "for_msg is nil" unless for_msg
    unless for_msg.trigger || for_msg.response_for.any?
      raise "for_msg is not associated with a trigger or trigger message"
    end
    ack_msg = Message.new
    ack_msg.message_type = find_or_create_message_type('ACK', 'General ACK')
    ack_msg.message_structure = general_ack_struct
    for_msg.ack = ack_msg
    ack_msg
  end
  
  def create_response_message(for_msg)
    # for_msg is the message that this ack is for
    resp_msg = Message.new
    for_msg.add_response(resp_msg)
    resp_msg
  end
  
  def reset_general_ack
    @general_ack_struct = nil
    @general_ack_ac     = nil
  end
  
  def general_ack_struct(msg_struct = nil)
    if msg_struct
      puts Rainbow("Setting ACK struct").gold # #{msg_struct.object_id}").gold
      # recorded_ack_structs = V2AD.v2.message_structures['ACK']&.values
      # recorded_ack_structs.each { |ras| puts "#{ras.class} #{ras.object_id}"}
      # puts "general_ack_struct is recorded? #{!!V2AD.v2.message_structures['ACK'].values.find { |ms| ms.object_id == msg_struct.object_id }}"
    end
    @general_ack_struct ||= msg_struct
  end
  
  def general_ack_ac(ac = nil)
    @general_ack_ac ||= ac
  end
  
  def add_table(t, source)
    v2.tables[t] ||= []
    v2.tables[t] << source
  end
  
  def add_msg_struct(msg_structure, section, opts = {})
    verbose = opts[:verbose]
    raise unless section
    code = msg_structure.code
    existing = v2.message_structures.dig(code, section)
    return if existing
    if v2.message_structures[code]
      puts Rainbow("#{code} is already registered from #{v2.message_structures[code].keys}!").orange if verbose && code != 'ACK'
    end
    v2.message_structures[code] ||= {}
    v2.message_structures[code][section] = msg_structure
    # if code == 'ACK'
      # puts Rainbow('Added ACK struct ' + msg_structure.object_id.to_s).magenta
    # end
  end
  
  def get_msg_struct(code, section)
    return unless code
    v2.message_structures.dig(code, section)
  end
  
  def get_segment_def(code, seg = nil)
    sd = v2.segment_defs[code]
    return sd if sd
    if seg
      ms  = seg.structure
      sec = ms.messages.first.trigger_for.section
      puts "Segment in #{ms.code} and section #{sec} with code #{code} has no seg def."
    end
    raise "No seg def for #{code}"
  end
  
  # For now we are just returning strings.  FIXME after we check message structures we can start to return actual message objects
  def get_message_codes(codes_str)
    codes_str.split(/\s*or\s*/)
  end
  
  def get_messages(message_codes)
    message_codes.map { |c| get_message(c) } 
  end

  def get_message(code)
    mt, ec, ms = code.split('^')
    event = V2.instance.events[ec]
    msg   = event.message
    msg
  end
  
  def add_section(s)
    existing = V2.instance.sections[s.num]
    raise "Section #{s.num} is already registered." if existing
    V2.instance.sections[s.num] = {obj:s, for:[]}
    # puts "added #{s.num}"
  end
  
  def add_data_element(de, code)
    V2.instance.data_elements[de.item_number] ||= {}
    V2.instance.data_elements[de.item_number][code] = de
  end
  
  def add_event(e, section)
    existing = V2.instance.events[e.code]
    if existing
      puts Rainbow("Event #{e.code} already exists! Exists in #{existing.map(&:section)} and also in #{section}").red
      # puts caller[0..4]
    end
    V2.instance.events[e.code] ||= []
    V2.instance.events[e.code] << e
  end
  
  def link_segment_defintions
    # pp v2.segment_defs.keys.sort
    v2.segments.each do |seg|
      seg.type = get_segment_def(seg.type, seg)
    end
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

module V2AD
  class Section
    attr_reader :num, :adoc, :title, :original_adoc, :content
    attr_accessor :sequel
    def initialize(id, asciidoc_lines, section_number = nil)
      if id =~ /\.0$/ && asciidoc_lines.first =~ /hidden text/
        # puts Rainbow("Skipping #{id}").red
        # puts asciidoc.lines
        # puts ':::::::::::'
        return nil 
      end
      @original_adoc = asciidoc_lines
      data = V2AD.process_text(asciidoc_lines, section_number)

=begin      FIXME
      if id =~ /\.0$/ && V2AD.empty_asciidoc?(asciidoc)
        # puts "Skipping #{id}"
        # puts asciidoc.lines
        # puts ':::::::::::'
        return nil 
      end
=end
      # original_lines = asciidoc.lines.dup
      @title   = data[:title]
      @content = data[:content]
      raise "ID from file and ID from text do not match" unless id == data[:number]
      @num = id # FIXME check that this is the same as what came back in data
                # title_line = nil
                # if asciidoc.lines&.first.to_s.strip =~ /^=/
                #   title_line = asciidoc.lines.shift
                # end
      debug = false
                # asciidoc.lines = get_asciidoc_body(asciidoc.lines, debug)
      
      # if title_line
      #   @title = title_line.sub(/^\s*=+\s*\*?[A\d\.]+\*?\s*/, '').chomp
      # elsif asciidoc.lines&.any?
      #   @title = "NO TITLE (from asciidoc) - FIXME"
      # else
      #   @title = "NO TITLE (no asciidoc)- FIXME"
      # end

      if @title.empty?
        if asciidoc_lines[1..]&.any? { |l| l.strip[0] }
          puts Rainbow(@num).lime
          puts caller.first
          pp asciidoc_lines
          raise
        else
          return nil if id =~ /\.0$/ 
        end
      end
      
      V2AD.add_section(self)
# adoc.register(@num)
# puts '-----'
      # puts Rainbow(self.title).cyan + " #{id}"
# puts adoc.lines
      # puts Rainbow(original_lines.first).yellow
      # puts
      self
    end
  end
  
  class Text
    attr_accessor :lines, :sequel
    def initialize(lines, remove_header = false)
      # lines = get_asciidoc_body(lines) if remove_header FIXME 
      @lines = lines
    end
    def register(section)
      V2AD.v2.sections[section][:for] << self
      V2AD.v2.texts << self
    end
  end

  # Abstract
  class V2Obj
    attr_accessor :section, :text, :adoc_source, :sequel
  end

  class Event < V2Obj
    attr_accessor :name, :code, :message, :status, :trigger
    def initialize(code, name, section, lines = nil)
      # if code == 'S01'
      #   puts Rainbow(section).orange
      #   puts caller[0..7]
      # end
      @code        = code
      @name        = name
      @section     = section
      @adoc_source = lines if lines
      message  = Message.new
      message.trigger_for = self
      @message = message
      @message.section = @section
      @message.adoc_source = @adoc_source
      V2AD.add_event(self, section)
      begin
        V2AD.v2.sections[section][:for] << self
      rescue
        puts "Looking for section #{section}"
        raise
      end
    end
    
    def display
      puts _display
    end
    
    def _display
      "#{section} #{code} #{name}"
    end
    
    def text=(txt)
      @text = txt
      @message.text = txt unless @message.text
    end
  end

  class MessageType < V2Obj
    attr_accessor :name, :code, :messages
    def initialize(code, section)
      raise if code.nil? || code.strip.size == 0
      @code = code
      @section = section
      @messages = []
      V2AD.v2.message_types[@code] = self
      # V2AD.v2.sections[section][:for] << self
    end
  end

  class Message < V2Obj
    attr_accessor :message_type, :message_structure, :responses, :ack, :response_for, :ack_for, :trigger_for, :ack_chor
    def initialize
      @responses     = []
      @response_for  = []
      @ack_for       = []
      V2AD.v2.messages << self
      # V2AD.v2.sections[section][:for] << self
    end
    
    def section
      return @section if @section
      return trigger.section if trigger
      return response_for.first.section if response_for.any?
      return ack_for.first.section if ack_for.any?
      return nil
    end
    
    def withdrawn?
      ev = (trigger || response_for.first&.trigger || ack_for.first&.trigger || ack_for.first.response_for.first.trigger)
      # pp trigger&.code
      # pp response_for.map(&:code)
      # pp ack_for.map(&:code)
      # pp ack_for.first.trigger&.code
      raise "No event for message #{code} from section #{section}" unless ev
      ev.status.to_s == 'W' || ev.status.to_s =~ /withdrawn/i
    end
        
    def trigger
      trigger_for
    end
    def trigger=(event)
      trigger_for = event
    end
    def structure
      message_structure
    end
    
    def ack_for_code
      if ack_for.size == 1
        af = ack_for.first
        af.trigger&.code || af.response_for_code
      else
        codes = ack_for.map { |af| af.trigger&.code || af.response_for_code }
        codes = codes.flatten.uniq
        if codes.size == 1
          codes.first
        elsif codes.size > 1
          raise "Multiple event codes for ACK message: #{codes}"
        else
          puts !!self.trigger
          puts self.response_for.size
          puts self.ack_for.size
          puts self.structure.code
          raise "No event associated with ACK message"
        end
      end
    end
    
    def response_for_code
      if response_for.size == 1
        rf = response_for.first
        rf.trigger.code
      else
        codes = response_for.map { |rf| codes << rf.trigger.code }
        codes.uniq!
        if codes.size == 1
          codes.first
        else
          raise "Multiple event codes for response message: #{codes}"
        end
      end
    end
    
    def event_code
      raise if response_for.size > 1
      ec = trigger&.code || response_for&.first&.trigger&.code || ack_for_code
      # unless ec
      #   raise 'AC for nothing?'
      # end
      ec
    end
    
    def code(strict = true)
      ec  = event_code
      mtc = message_type&.code
      sc  = structure&.code
      ret = "#{mtc || '***'}^#{ec || '***'}^#{sc || '***'}"
      if !(ec && mtc && sc) && !(trigger&.status == 'W')
        unless ['E30', 'E31'].include?(ec)
          puts Rainbow("Message #{ret} with malformed code from section: #{section}").orange
          if strict
            puts trigger&.status
            puts "Event code: " + ec
            puts "Message type: " + (mtc || 'NONE')
            puts "Structure: " + (sc || 'NONE')
            raise 
          end
        end
      end
      ret
    end
    
    def add_response(msg)
      @responses << msg
      msg.response_for << self
    end
    
    def ack=(msg)
      @ack = msg
      msg.ack_for << self
    end
    
    def message_structure=(ms)
      @message_structure = ms
      ms.messages << self
    end
    
    def message_type=(mt)
      @message_type = mt
      mt.messages << self
    end
    
    def ack_chor=(ac)
      @ack_chor = ac
      ac.for << self
    end
  end

  class MessageStructure < V2Obj
    attr_accessor :messages, :segments, :code, :withdrawn
    def initialize(code, section)
      @code     = code
      @segments = []
      @messages = []
      V2AD.v2.sections[section][:for] << self
    end
    
    def serialize
      json
    end
    
    def json
      { message_structure: to_hash_all}
    end
    
    def to_hash_all
      unless segments.is_a?(Array)
        pp segments
        puts '________'
        pp self
      end
      {
        code:code,
        withdrawn:!!withdrawn,
        segments:segments.map(&:to_hash_all) # segment_definitions
      }
    end
    
    def to_hash_vals
      {
        code:code,
        withdrawn:!!withdrawn,
        segments:segments.map(&:to_hash_vals) # segment_definitions
      }
    end
  end

  class AbstractSegment < V2Obj
    attr_accessor :container, :name, :repeat, :optional, :status, :footnote
    def structure
      return container if container.is_a?(V2AD::MessageStructure)
      container.structure
    end
  end

  class Segment < AbstractSegment
    attr_accessor :type
    def initialize(name)
      @name = name
      V2AD.v2.segments << self
    end
    
    def json
      data = {
        code:type.code,
        name:name,
        repeat:repeat,
        optional:optional
      }
      data[:status] = status if status
      {segment:data}
    end
    
    def to_hash_all
      json
    end
    
    def to_hash_vals
      {segment:json[:segment].reject { |k,_| k == :name } }
    end
  end

  class SegmentSequence < AbstractSegment
    attr_accessor :segments
    def initialize(name)
      @name = name
      @segments = []
      V2AD.v2.seg_seqs << self
    end
    
    def json
      {segment_sequence:{
        name:name,
        repeat:repeat,
        optional:optional,
        segments:segments.map(&:json)
      }}
    end

    def to_hash_all
      json
    end
    
    def to_hash_vals
      {segment_sequence:{
        name:name,
        repeat:repeat,
        optional:optional,
        segments:segments.map(&:to_hash_vals)
      }}
    end
  end

  class SegmentChoice < AbstractSegment
    attr_accessor :groups
    def initialize(name)
      @name   = name
      @groups = []
    end
    
    def json
      {segment_choice:{
        name:name,
        repeat:repeat,
        optional:optional,
        choices:groups.map(&:json)
      }}
    end
    
    def to_hash_all
      json
    end
    
    def to_hash_vals
      {segment_sequence:{
        name:name,
        repeat:repeat,
        optional:optional,
        choices:groups.map(&:to_hash_vals)
      }}
    end
  end
  
  class SegmentGroup < AbstractSegment
    attr_accessor :segments, :choice
    def initialize(choice)
      @choice   = choice
      @segments = []
    end
    
    def json
      segments.map(&:json)
    end
    
    def to_hash_all
      json
    end
    
    def to_hash_vals
      segments.map.map(&:to_hash_vals)
    end
  end

  class ExampleSegment < AbstractSegment
    def initialize(name)
      @name = name
    end
    def json
      {example_segment:{
        name:name,
        repeat:repeat,
        optional:optional
      }}
    end
    
    def to_hash_all
      json
    end
    
    def to_hash_vals
      json
    end
  end

  class SegmentDefinition < V2Obj
    attr_accessor :fields, :name, :withdrawn, :code
    def initialize(code, name, section)
      @fields = []
      @code = code
      @name = name
    end
    
    def add_field(field)
      @fields << field
      field.owner = self
    end
  end

  class Field < V2Obj
    attr_accessor :seq, :data_element, :must_support, :min_card, :max_card, :opt, :flags, :repetition, :addendum_type, :definition_text, :description, :owner
    def initialize(seq)
      @seq = seq
    end
    def data_element=(de)
      @data_element = de
      de.fields << self
    end
  end

  class DataElement < V2Obj
    attr_accessor :name, :item_number, :min_length, :max_length, :c_length, :may_truncate, :datatype_varies, :datatype, :definition_text, :table, :fields
    def initialize(item_number, min_length, max_length, c_length, datatype, opt, section)
      @item_number = item_number
      @min_length  = min_length
      @max_length  = max_length
      @c_length    = c_length
      @fields      = []
      if datatype&.[](0)
        self.datatype = V2AD.find_or_create_datatype(datatype, section)
      else
        raise if opt != 'W'
      end
      # datatype_varies = true unless datatype
    end
    def datatype=(dt)
      @datatype = dt
      dt.data_elements << self
    end
    
    def set_table(tbl, segment_code, section)
      @table = V2AD.remove_links(tbl, section)
      # puts "DataElement table: #{tbl} --> #{@table}" if tbl =~ /\\\\/
      V2AD.add_table(self.table, "#{segment_code} from #{section}")
    end
    
    def diff_str
      [attr_diff_str, def_diff_str].join("\n")
    end
    
    def attr_diff_str
      a = []
      a << "item_number:#{item_number},"
      a << "name:#{name},"
      a << "min_length:#{min_length},"
      a << "max_length:#{max_length},"
      a << "c_length:#{c_length},"
      a << "may_truncate:#{may_truncate},"
      a << "dt_varies:#{datatype_varies},"
      a << "data_type:#{datatype&.code},"
      a << "table:#{table},"
      a.join("\n")
    end
    
    def def_diff_str
      "definition:#{definition_text}"
    end
    
    def json
      # return diff_str
      # unless datatype
      #   puts "No datatype for #{item_number} from #{fields.map { |f| f.owner.code + '-' + f.seq.to_s}.join(',') }"
      # end
      {item_number:item_number, name:name, min_length:min_length, max_length:max_length, c_length:c_length, may_truncate:may_truncate, dt_varies:datatype_varies, data_type:datatype&.code, table:table, definition:definition_text}.to_json
    end
  end

  class DefinitionText < V2Obj
    attr_accessor :definition, :description
  end

  class Datatype < V2Obj
    attr_accessor :name, :code, :components, :primitive, :data_elements, :array_type
    def initialize(code, section_number, name = nil)
      @code = code
      @name = name
      @components = []
      @primitive = nil
      @data_elements = []
      @fields = []
      V2AD.v2.sections[section_number][:for] << self
    end
  end

  class Component < V2Obj
    attr_accessor :seq, :len, :clen, :datatype, :opt, :table, :name, :comments, :sec_ref, :parent
    def initialize(row, datatype_code)
      row = row.map { |x| x.strip == '' ? nil : x }
      @seq, @len, @clen, @datatype, @opt, tbl, @name, @comments, @sec_ref = row
      @table = V2AD.remove_links(tbl, section) if tbl
      # puts "Component table: #{tbl} --> #{@table}" if tbl =~ /\\\\/
      V2AD.add_table(self.table, "DT #{datatype_code} from #{section}") if self.table
    end
    def section=(section_number)
      @section = section_number
      V2AD.v2.sections[section_number][:for] << self
    end
  end
  
  class AcknowledgementChoreography
    attr_accessor :ack_immediate, :original_acks, :msh15_acks, :msh16_acks, :imm_ack, :app_ack, :notes, :for, :msh15, :msh16, :sequel, :section
    def initialize(section)
      @section = section
      @for = []
      @original_acks = []
      @msh15_acks = []
      @msh16_acks = []
      V2AD.v2.ack_chors << self
    end
  end
end
