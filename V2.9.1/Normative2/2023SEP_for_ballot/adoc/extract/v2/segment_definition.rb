module V2AD

  class SegmentDefinition < V2Obj
    attr_accessor :fields, :name, :withdrawn, :code
    def initialize(code, name, section)
      @section = section || Section.new(nil, nil) # obviously a hack...
      @fields  = []
      @code    = code
      @name    = name
      V2AD.v2.segment_defs[code] = self
      V2AD.register_to_section(section, self) if section
    end
    
    def add_field(field)
      @fields << field
      field.owner = self
    end
  end

  module_function
  
  def get_segment_def(code, seg = nil)
    sd = v2.segment_defs[code]
    return sd if sd
    if seg
      ms  = seg.structure
      sec = ms.messages.first.trigger.section
      puts "Segment in #{ms.code} and section #{sec.num} with code #{code.inspect} has no seg def."
    end
    v2sds = v2.segment_defs
    puts v2sds.keys.sort
    puts v2sds.size
    raise "No seg def for #{code.inspect}"
  end
  
  def link_segment_defintions
    # pp v2.segment_defs.keys.sort
    v2.segments.each do |seg|
      seg.type = get_segment_def(seg.type.strip, seg)
    end
  end
  
end
