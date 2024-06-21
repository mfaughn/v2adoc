module V2AD

  class MessageType < V2Obj
    attr_accessor :name, :code, :messages
    def initialize(code, section)
      raise if code.nil? || code.strip.size == 0
      @code = code
      @section = section
      @messages = []
      V2AD.v2.message_types[@code] = self
    end
  end
  
end
