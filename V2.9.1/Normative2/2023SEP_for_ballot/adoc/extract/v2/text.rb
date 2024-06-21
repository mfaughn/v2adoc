module V2AD

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
  
  class DefinitionText < V2Obj
    attr_accessor :definition, :description
  end
  
end
