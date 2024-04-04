module V2AD
  class ContentObj
  end

  class Table < ContentObj
    attr_accessor :caption, :header, :rows, :type, :declaration, :possible_caption
    def initialize
      @rows = []
    end
    
    def finalize
      get_type_from_header if self.type.nil?
      self.type = :other if self.type.nil?
    end
    
    def summary
      type_str = type ? "(#{type})" : ''
      if type == :ack_chor
        cap = rows[2].delete('|').strip
      end
      cap ||= caption ? caption : (possible_caption ? "<possible_caption>: #{possible_caption}" : 'NO CAPTION')
      str = "TABLE#{type_str}: #{cap}"
      puts str
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
    
    def summary
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
      # @type = :paragraph
    end
  end
  
  class Example < Block # TODO should this instead inherit from Paragraph?  Does it matter?
    def initialize
      super
      # @type = :example
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
      # @type = :er7
    end
    def summary
      x = "ER7(#{content.size}): "
      puts Rainbow(x).magenta + "#{content.map { |c| c[0..30]}.join("\n" + " "*x.size) }"
    end
  end
  
  class Definition < Block
    def initialize
      super
      # @type = :definition
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
  
  module_function

  def process_text(val, info = nil)
    # puts Rainbow(info).cornflower if info
    data = TextProcessor.new(val, info).process_text
  end
  



  def get_asciidoc_body(val, debug = false)
    raise "Do not use this method"
    lines = nil
    if val.is_a?(String)
      lines = val.split("\n")
    elsif val.is_a?(Array)
      lines = val.dup
    else
      raise "I can't deheaderize this: #{val.inspect}"
    end
    trimmed = nil
    header = lines.shift if lines&.first.to_s.strip =~ /^=+/
    lines.each_with_index do |l, i|
      puts "#{i} " + Rainbow(l).green if debug
      next if l.strip.empty?
      trimmed = lines[i..-1]
      break
    end
    if debug
      puts "ORIGINAL:"
      puts val
      puts "TRIMMED:"
      puts trimmed
      raise
    end
    return [] unless trimmed
    trimmed.reverse!
    trimmed.each_with_index do |l, i|
      next if l.strip.empty?
      return trimmed[i..-1].reverse
    end
    
  end

end  
