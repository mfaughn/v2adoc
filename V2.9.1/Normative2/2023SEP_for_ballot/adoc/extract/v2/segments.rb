module V2AD

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
  
end
