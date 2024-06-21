module V2AD

  class Section
    attr_reader :num, :title, :original_adoc, :content, :data
    attr_accessor :sequel
    def initialize(id, asciidoc_lines)
      if id =~ /\.0$/ && asciidoc_lines.first =~ /hidden text/
        # puts Rainbow("Skipping #{id}").red
        # puts asciidoc.lines
        # puts ':::::::::::'
        return nil 
      end
      @num = id ? id : 'N/A'
      @original_adoc = asciidoc_lines || ''
      @data = V2AD.process_text(asciidoc_lines, self) if asciidoc_lines
      if id && (data[:number] != @num)
        raise "Passed id: #{id.inspect} does not match number from text processing #{data[:number]}"
      end


=begin      FIXME
      if id =~ /\.0$/ && V2AD.empty_asciidoc?(asciidoc)
        # puts "Skipping #{id}"
        # puts asciidoc.lines
        # puts ':::::::::::'
        return nil 
      end
=end
      @title   ||= @data[:title] if data
      @content ||= @data[:content] if data
      if id
        raise "ID from file and ID from text do not match" unless id == @data[:number]
      end

      debug = false
      
      if id && @title.empty?
        if asciidoc_lines[1..]&.any? { |l| l.strip[0] }
          puts Rainbow(@num).lime
          puts caller.first
          pp asciidoc_lines
          raise
        else
          return nil if id =~ /\.0$/ 
        end
      end
      
      V2AD.add_section(self) if id
# puts '-----'
      # puts Rainbow(self.title).cyan + " #{id}"
      # puts Rainbow(original_lines.first).yellow
      # puts
      self
    end
    
    def tables
      content.select { |c| c.is_a?(Table) }
    end
    
    def display(opts = {})
      str = "#{num} - #{title}"
      color = opts[:color]
      puts (color ? Rainbow(str).send(color.to_sym) : str)
      if opts[:content]
        puts "[ #{content.map { |c| c.class.name.split('::').last }.join(', ')} ]"
      end
    end
  end
  
  module_function
  
  
  def add_section(s)
    existing = V2.instance.sections[s.num]
    raise "Section #{s.num} is already registered." if existing
    V2.instance.sections[s.num] = {obj:s, for:[]}
    # puts "added #{s.num}"
  end
  
  def register_to_section(section, obj)
    begin
      fors = V2AD.v2.sections.dig(section.num, :for) 
      fors << obj
    rescue
      puts "Section #{section.num} appears to be unregistered."
      raise
    end
  end

end
