module V2AD

  class MessageStructure < V2Obj
    attr_accessor :messages, :segments, :code, :withdrawn
    def initialize(code, section)
      @code     = code
      @segments = []
      @messages = []
      @section  = section
      V2AD.register_to_section(section, self)
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
  
  module_function
  
  def add_msg_struct(msg_structure, section, opts = {})
    verbose = opts[:verbose]
    raise unless section
    code = msg_structure.code
    existing = v2.message_structures.dig(code, section.num)
    return if existing
    if v2.message_structures[code]
      puts Rainbow("#{code} is already registered from #{v2.message_structures[code].keys}!").orange if verbose && code != 'ACK'
    end
    v2.message_structures[code] ||= {}
    v2.message_structures[code][section.num] = msg_structure
    # if code == 'ACK'
      # puts Rainbow('Added ACK struct ' + msg_structure.object_id.to_s).magenta
    # end
  end
  
  def get_msg_struct(code, section_num)
    return unless code
    v2.message_structures.dig(code, section_num)
  end

end
