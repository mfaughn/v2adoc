module V2AD

  class Datatype < V2Obj
    attr_accessor :name, :code, :components, :primitive, :data_elements, :array_type
    def initialize(code, section, name = nil)
      @code          = code
      @name          = name
      @section       = section
      @components    = []
      @primitive     = nil
      @data_elements = []
      @fields        = []
      V2AD.v2.datatypes[code] = self
      V2AD.register_to_section(section, self)
      if @code == 'AD'
        puts Rainbow(@code).lime + ' ' +  @section.object_id.to_s
        pp @section.data
      end
    end
    
    def add_component(comp)
      @components << comp
      comp.parent = self
    end
  end

end
