module V2AD
  module_function

  def create_variable_segment_def
    segdef = V2AD::SegmentDefinition.new('...', 'Variable', nil)
    V2AD.v2.segment_defs['...'] = segdef
  end
  
  def create_Hxx_segment_def
    segdef = V2AD::SegmentDefinition.new('Hxx', 'Any segment or segment group', nil)
    V2AD.v2.segment_defs['Hxx'] = segdef
  end
  
  def extract_segment(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]
    return if section_num == '4A.8.1' # This is a profile on the RXA segment and not a separate segment definition    
    l1 = section.title
    # puts l1
    # FIXME this does not cover the variable segment (...) or the Hxx segment
    code = l1.slice(/^[A-Z][A-Z][A-Z0-9]\s*(?=[–‑-])/)&.strip
    name = l1.slice(/(?<=[–‑-]).+(?=Segment)/i)&.strip
    raise "#{section_num} No segment name in #{l1}" unless name
    # puts (code && name) ? Rainbow(section_num).green : Rainbow(section_num).red
    # puts Rainbow(name).orange
    # puts code;return
    
    puts Rainbow('SegDef ').green + "#{section_num} #{code} - #{name}" if verbose
    unless code
      raise "No code found in #{section.title}" 
    end

    segdef = V2AD::SegmentDefinition.new(code, name, section)

    segdef_tables = section.tables.select { |tbl| tbl.type == :segment_definition }
    raise unless segdef_tables.size == 1
    segdef_tables.first.objects << segdef
    processed_table = process_segment_table(segdef_tables.first, section, :segment => code) 
    processed_table.each { |field| segdef.add_field(field) }
  end
  
  def remove_segment_tables(lines)
    text_buffer = []
    table_counter = 0
    lines.each do |l|
      next if l =~ /Attribute Table/
      next if l =~ /width=/
      if l =~ /\|===/
        table_counter += 1
        next
      end 
      text_buffer << l if table_counter.even?
    end
    text_buffer = remove_leading_and_trailing_blank_lines(text_buffer)
    # text_buffer.each { |tb| puts Rainbow(tb.inspect).lightskyblue }
    text_buffer
  end
  
  def remove_leading_and_trailing_blank_lines(lines)
    str = lines.join("\n").gsub(/\n\n+/m, "\n\n").sub(/^\n+/m, '').sub(/\n$+/m, '').split("\n")
    # str = lines.join("\n").sub(/^\n+/m, '').sub(/\n+$/m, '').split("\n")
  end
  
  def process_segment_table(table, section, opts)
    section_num = section.num
    rows = table.rows[1..-2].dup
    header = rows.shift
    cols = []
    split_row(header).each_with_index { |x, i| cols << i if x.strip[0] }
    unless cols.size == 9
      puts header
      raise "Wrong number of columns in segdef header"
    end
    code = opts[:segment]
    fields = []
    rows.each do |r|
      field = process_field_row(r, cols, code, section)
      if field
        fields << field
        V2AD.v2.fields["#{code}-#{field.seq}"] = field
      end
    end
    sff = subsection_files(section)
    # puts sff.sort
    # puts section_num
    fields.each do |fd|
      next if section_num == '15.4.7' # because they just aren't there...
      field_section_num = "#{section_num}\.#{fd.seq.sub('-n', '')}"
      field_section = V2AD.v2.sections.dig(field_section_num, :obj)
      raise "No section for #{field_section_num}" unless field_section
      fd.section = field_section
      # field_section.display(content:true)
      defns = field_section.content.select { |c| c.is_a?(Definition) }
      descriptions = field_section.content.reject { |c| c.is_a?(Definition) || c.is_a?(DataTypeComponent)}
      # fscontent = field_section.content.reject { |c| c.class.name =~ /Component/ }
      # field_section.display(color: :magenta)
      # fscontent.each(&:display)
      if descriptions.any?
        fd.description = descriptions.map do |d| 
          if d.is_a?(Table)
            # FIXME do we need to convert Asciidoc to Markdown here?
            ([(d.caption || d.possible_caption)] + d.rows).join("\n")
          elsif d.is_a?(Block)
            d.content
          else
            raise "What the heck is this? #{d.inspect}"
          end
        end.join("\n\n").gsub(/\n\n+/, "\n\n") 
      end
      
      if defns.size > 1
        defns.each(&:display)
        raise "Whoa, multiple definitions in #{field_section_num} for #{code}-#{fd.seq}" unless ['6.5.11.9'].include?(field_section_num) 
      end
      if defns.size < 1
        # puts Rainbow("No definition for #{code}-#{fd.seq} in section  #{field_section_num}").coral
        next
      end
      fd.definition_text = defns.first
      fd.data_element.definition_text = defns.first
      
      # FIXME the rest of this stuff can go away after we're sure the stuff above works well
      sf = sff.find { |f| f =~ /#{field_section_num}\.adoc/ }
      # puts fd.seq
      if sf.nil? && fd.seq == '1-n'
        sf = sff.find { |f| f =~ /2\.13\.1\.1\.adoc/ }
      end
      unless sf
        puts Rainbow(code.to_s + '-' + fd.seq).red + " No adoc for #{section_num}.#{fd.seq}"
        puts "sff: \n#{sff.sort.join("\n")}"
        next
      end
    end
    fields
  end
  
  # TODO registering the data element requires the ability to differentiate multiple instances of the same data element
  # This can probably best be acheived by attaching it to the segdef identifier of the field, e.g., MSH-1k
  def process_field_row(line, cols, segment_code, section)
    section_num = section.num
    raw_row = split_row(line, unbold:true)
    # puts line.inspect
    row = cols.map { |c| raw_row[c] }
    seq, len, clen_and_flag, dt, opt, rp, tbl, item_number, name = row
    # tbl = remove_links(tbl, section_num)
    # puts row.inspect
    if seq
      field = V2AD::Field.new(seq)
      min_length, max_length = len.split(/\.+/)
      clen = clen_and_flag.slice(/\d+/)
      begin
        de = V2AD::DataElement.new(item_number, min_length, max_length, clen, dt.strip, opt, section)
      rescue
        puts "#{segment_code}-#{field.seq}"
        raise
      end
      V2AD.add_data_element(de, "#{segment_code}-#{field.seq}")
      field.data_element = de
      field.opt = opt
      field.repetition = rp
      if clen_and_flag =~ /#|=/
        de.may_truncate = false if clen_and_flag =~ /=/
        de.may_truncate = :inherit_from_datatype if clen_and_flag =~ /#/
      else
        de.may_truncate = true # TODO is this really correct?  or is it 'N/A'?
      end
      de.set_table(tbl, "#{segment_code}-#{field.seq}", section) if tbl[0]
      return field
    else
      raise "No seq for #{line}"
    end
  end

end  
