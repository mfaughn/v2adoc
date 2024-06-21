module V2AD

  class Field < V2Obj
    attr_accessor :seq, :data_element, :must_support, :min_card, :max_card, :opt, :flags, :repetition, :addendum_type, :definition_text, :description, :owner
    def initialize(seq)
      @seq = seq
    end

    def data_element=(de)
      @data_element = de
      de.fields << self
    end
    
    def section=(sect)
      @section = sect
      V2AD.register_to_section(@section, self)
    end
    
    def code
      "#{owner.code}.#{seq}"
    end
  end

end
