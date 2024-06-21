module V2AD
  class ContentObj
  end

  class Table < ContentObj
    attr_accessor :caption, :header, :rows, :type, :declaration, :possible_caption, :objects
    def initialize
      @rows    = []
      @objects = []
    end
    
    def finalize
      get_type_from_header if self.type.nil?
      self.type = :other if self.type.nil?
    end
    
    def display(color = nil)
      type_str = type ? "(#{type})" : ''
      if type == :ack_chor
        cap = rows[2].delete('|').strip
      end
      cap ||= caption ? caption : (possible_caption ? "<possible_caption>: #{possible_caption}" : 'NO CAPTION')
      str = "TABLE#{type_str}: #{cap}"
      puts (color ? Rainbow(str).send(color.to_sym) : str)
      puts rows[1..3] if type.nil?
    end
    
    def get_header
      header_row = rows.first
      header_row = rows[1] if header_row =~ /\|===/
      header_row
    end
    
    def get_type_from_header
      header_str = V2AD.remove_empty_cells(get_header)
      if header_str =~ V2AD.message_structure_table_header_regex
        self.type = :message_structure
        return
      end

      if header_str =~ V2AD.ack_chor_table_regex
        self.type = :ack_chor
        return
      end
      
      if header_str =~ V2AD.segment_table_header_regex
        self.type = :segment_definition
        return
      end
      
      if header_str =~ V2AD.datatype_table_header_regex
        self.type = :datatype_definition
        return
      end
    end
    
    def get_message_codes_from_caption
      unless caption || possible_caption
        pp self
        raise "No caption or possible_caption for table."
      end
      if type == :ack_message_structure
        str = caption.slice(V2AD.ack_message_code_regex) || caption.slice(V2AD.ack_message_code_regex_multiple_events)
        unless str
          display
          puts "Normal: " + V2AD.ack_message_code_regex.inspect
          puts "Multi:  " + V2AD.ack_message_code_regex_multiple_events.inspect
          raise "Can't deduce codes for table."
        end
      elsif type.to_s =~ /message_structure/      
        if caption
          str = caption.slice(V2AD.query_message_code_regex) || caption.slice(V2AD.response_message_code_regex) || caption.slice(V2AD.message_code_regex) || caption.slice(V2AD.message_code_regex_multiple_events)
        end
        unless str
          display
          puts "Normal: " + V2AD.message_code_regex.inspect
          puts "Multi:  " + V2AD.message_code_regex_multiple_events.inspect
          # puts V2AD.message_structure_table_caption_regex
          raise "Can't deduce codes for table."
        end
        # else
        #   str = possible_caption.slice(V2AD.message_code_regex_multiple_events)
        #   unless str
        #     display
        #     puts V2AD.message_code_regex_multiple_events.inspect
        #     raise "Can't deduce codes for table."
        #   end
      end
      msg_type_code, event_code, msg_structure_code = str.split('^')
      [msg_type_code, event_code, msg_structure_code]
    end
  end
  
  class Block < ContentObj
    attr_accessor :content#, :type
    def initialize
      # @type = :block
      @content = []
    end
    
    def add_content(x)
      @content << x
    end
    
    def last
      @content.last
    end
    
    def display
      puts "#{self.class.name.split('::').last}(#{content.size}): #{content.map { |c| c[0..30]}.join(' | ')}"
    end
        
  end  
  
  class Image < Block
    def initialize
      super
    end
  end  

  class Paragraph < Block
    def initialize
      super
    end
  end
  
  class Note < Block
    def initialize
      super
    end
  end
  
  class Example < Block
    def initialize
      super
    end
  end
  
  class Code < Block
    def initialize
      super
    end
  end
  
  class ER7 < Code
    def initialize
      super
    end
    def display
      x = "ER7(#{content.size}): "
      puts Rainbow(x).darkseagreen + "#{content.map { |c| c[0..30]}.join("\n" + " "*x.size) }"
    end
  end
  
  class ER7Snippet < ER7
    def initialize
      super
    end
    def display
      x = "ER7Snippet(#{content.size}): "
      puts Rainbow(x).lightgreen + "#{content.map { |c| c[0..30]}.join("\n" + " "*x.size) }"
    end
  end
  
  class Definition < Block
    def initialize
      super
    end
  end
  
  class DataTypeComponent < Block
    def initialize
      super
    end
  end
  
  class DataTypeSubComponent < Block
    def initialize
      super
    end
  end

end  
