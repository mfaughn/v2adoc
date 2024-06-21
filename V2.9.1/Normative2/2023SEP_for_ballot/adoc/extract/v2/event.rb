module V2AD

  class Event < V2Obj
    attr_accessor :name, :code, :message, :status
    def initialize(code, name, section)
      # if code == 'S01'
      #   puts Rainbow(section).orange
      #   puts caller[0..7]
      # end
      @code        = code
      @name        = name
      @section     = section
      @responses   = []
      message  = Message.new(section)
      message.trigger = self
      @message = message
      V2AD.add_event(self, section)
      V2AD.register_to_section(section, self)
    end
    
    def display
      puts _display
    end
    
    def _display
      "#{section.num} #{code} #{name}"
    end
    
  end
  
  module_function
  
  def add_event(e, section)
    existing = V2.instance.events[e.code]
    if existing
      puts Rainbow("Event #{e.code} already exists! Exists in #{existing.map(&:section).map(&:num)} and also in #{section.num}").red
      # puts caller[0..4]
    end
    V2.instance.events[e.code] ||= []
    V2.instance.events[e.code] << e
  end

end
