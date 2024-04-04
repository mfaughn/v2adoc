require_relative 'content_classes'
module V2AD
  class TextProcessor
    attr_accessor :content, :data #, :lines
    attr_reader :val, :info, :lines
    def initialize(val, info)
      @val     = val
      @info    = info
      @content = []
      @data    = {}
      reset
    end
    
    def reset
      @table_marker = 0
      @table_start_content_index = nil
    end
    
    def process_text
      block = nil
      table = nil
      if val.is_a?(String)
        lines = val.split("\n")
      elsif val.is_a?(Array)
        lines = val.dup
      else
        raise "I can't process this: #{val.inspect}"
      end
      lines = lines.map(&:chomp).map(&:strip)
      
      # get title and number
      l1 = lines&.first.to_s.strip
      if l1 =~ /^=+/
        l1 = l1.sub(/^=+/, '').strip
        number = l1.slice(V2AD.section_number_regex)
        puts Rainbow(info).coral + " #{l1}" unless number
        number.strip!
        title  = l1.sub(number, '').strip
        data[:title]  = title
        data[:number] = number.delete('*')
        lines.shift
        puts Rainbow(data.to_s).green
      else
        data[:title]  = nil
        data[:number] = nil
        puts Rainbow(lines.first).orange
        lines.each { |l| puts Rainbow(l).yellow }
      end

      # process remaining lines
      lines.each_with_index do |line, i|
        next if i == 0 && line.strip.empty? # skip first line if it is empty
        next if line == '____'
        if line =~ /\[width="\d+%",cols=/
          content << block if block
          block = nil
          table = Table.new
          @table_marker += 1
          table.declaration = line
          table_start_content_index = content.size # I think!  Note sure we need this???  FIXME remove if unneeded.
          next
        end

        if line.strip =~ /\|===/
          @table_marker += 1
          table.rows << line
          if @table_marker == 3 # We have reached the end of the table
            lc = get_last_content
            caption, type = get_caption_and_type(lc)
            
            content << table
            
            if caption
              table.caption = caption 
            else
              table.possible_caption = lc if lc.is_a?(String)
            end
            
            table.type = type if type
            table.finalize
            # table.summary

            # reset
            @table_start_content_index = nil
            @table_marker = 0
          end
          raise if @table_marker > 3
          next
        end
        
        if @table_marker < 1 # we aren't in a table
          last_content_obj = content.last
          if line.empty?
            if block
              content << block 
              block = nil
            end
            next # Technically unnecessary if this is written correctly but leaving it here for clarity / readability
            # lc = content.last
            # next if lc.is_a?(Block) && lc.content.empty? # this is an empty line that followed another empty line so we skip it
          else # not empty and not inside a table
            if V2AD.is_er7?(line)
              if block.is_a?(ER7)
                block.add_content(line)
              else
                content << block if block
                block = ER7.new
                block.add_content(line)
              end
              next
            end
            if V2AD.is_data_type_component_expression?(line)
              block = DataTypeComponent.new
              block.add_content(line)
              next
            end
            if V2AD.is_data_type_subcomponent_expression?(line)
              block = DataTypeSubComponent.new
              block.add_content(line)
              next
            end
            if V2AD.is_definition?(line)
              block = Definition.new
              block.add_content(line)
              next
            end
            if V2AD.is_image?(line)
              block = Image.new
              block.add_content(line)
              next
            end
            block ||= Paragraph.new
            block.add_content(line)
          end
        else # we are in a table
          table.rows << line # do we want to further process this table later?  extract the header, e.g.? Might happen later on. TODO ...
        end
      end
      finalize_content
      content.each(&:summary)
      data[:content] = content
      return data
    end

    def finalize_content
      finalized = []
      er7 = nil
      content.each do |c|
        if c.is_a?(ER7)
          if finalized.last.is_a?(ER7)
            finalized.last.content += c.content
          else
            finalized << c
          end
        else
          finalized << c
        end
      end
      @content = finalized
    end

    def get_caption_and_type(last_content)
      return [nil, nil] if last_content == :table || last_content.nil?
      possible_caption = last_content
      type             = caption_type(possible_caption)
      if type # in this case we got the type from the caption, so we know that it was a caption
        remove_caption_from_content
        [possible_caption, type]
      else
        # puts Rainbow("caption?: ").gold + possible_caption
        [nil, nil]
      end
    end
    
    def get_last_content
      return nil if content.empty?
      lc = content.last
      return :table if lc.is_a?(V2AD::Table)
      last_content_line = lc.last
      last_content_line
    end
    
    def remove_caption_from_content
      caption = content.pop
    end
    
    def caption_type(str)
      return :message_structure     if str =~ V2AD.message_structure_table_caption_regex
      return :message_structure     if str =~ V2AD.response_message_structure_table_caption_regex
      return :message_structure     if str =~ V2AD.query_message_structure_table_caption_regex
      return :ack_message_structure if str =~ V2AD.ack_message_structure_table_caption_regex
      return :segment_definition    if str =~ V2AD.segment_defitiniton_table_caption_regex
      return :datatype_definition   if str =~ V2AD.data_type_defitiniton_table_caption_regex
      nil
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
