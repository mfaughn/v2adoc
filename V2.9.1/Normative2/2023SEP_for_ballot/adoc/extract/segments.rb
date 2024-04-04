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
  
  def extract_segment(lines, section, opts = {})
    verbose = opts[:verbose]
    return if section == '4A.8.1' # This is a profile on the RXA segment and not a separate segment definition    
    l1 = lines.shift
    # puts l1
    # FIXME this does not cover the variable segment (...) or the Hxx segment
    code = l1.slice(/(?<=\d)\s+[A-Z][A-Z][A-Z0-9]\s*(?=[–‑-])/)&.strip
    name = l1.slice(/(?<=[–‑-]).+(?=Segment)/i)&.strip
    raise "#{section} No segment name in #{l1}" unless name
    # puts (code && name) ? Rainbow(section).green : Rainbow(section).red
    # puts Rainbow(name).orange
    # puts code;return
    
    puts Rainbow('SegDef ').green + "#{section} #{code} - #{name}" if verbose
    raise unless code

    segdef = V2AD::SegmentDefinition.new(code, name, section)
    V2AD.v2.segment_defs[code] = segdef
    segdef.section = section
    segdef.adoc_source = lines
    segdef.text = Text.new(remove_segment_tables(lines), true)
    # lines.each { |l| puts Rainbow(l).lightskyblue }
    # puts Rainbow('-'*33).orange
    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    lines.each_with_index do |l, i|
      if l =~ /\[width="\d+%",cols=/ # a table is next
        table = true
      else
        if table
          if l.strip =~ /\|==+/
            table_mark += 1
            if table_mark > 1
              table = false
              table_mark = 0
            end
            next
          end
          table_buffer << l
        else
          if table_buffer.any?
            table_type, processed_table = process_table(table_buffer, section, :segment => code) 
            if table_type == :segment_definition
              text_buffer << '\include::segment_table'
              # pp processed_table
              processed_table.each { |field| segdef.add_field(field) }
              # segdef.fields = processed_table
            elsif table_type == :other
              text_buffer += processed_table
            else
              puts processed_table
              # puts "TEXT BUFFER"
              # pp text_buffer
              # puts "TABLE BUFFER"
              # pp table_buffer
              raise "Wrong kind of table!! -- #{table_type}"
            end
            table_buffer = []
          end
          text_buffer << l
        end
      end
    end
    segdef.text = text_buffer.join("\n").gsub(/\n+/, "\n") unless text_buffer.reject { |x| x.strip == '' }.empty?
    # pp segdef
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
  
  def process_segment_table(lines, section, opts)
    header = lines.shift
    cols = []
    split_row(header).each_with_index { |x, i| cols << i if x.strip[0] }
    unless cols.size == 9
      puts header
      raise "Wrong number of columns in segdef header"
    end
    code = opts[:segment]
    fields = []
    lines.each do |l|
      field = process_field_row(l, cols, code, section)
      if field
        fields << field
        V2AD.v2.fields["#{code}-#{field.seq}"] = field
      end
    end
    sff = subsection_files(section)
    # puts sff.sort
    # puts section
    fields.each do |fd|
      sf = sff.find { |f| f =~ /#{section}\.#{fd.seq.sub('-n', '')}\.adoc/ }
      # puts fd.seq
      if sf.nil? && fd.seq == '1-n'
        sf = sff.find { |f| f =~ /2\.13\.1\.1\.adoc/ }
      end
      unless sf
        puts Rainbow(code.to_s + '-' + fd.seq).red + " No adoc for #{section}.#{fd.seq}" unless section == '15.4.7'
        next
      end
      buffer = []
      lines = File.readlines(sf)
      fd.adoc_source = lines
      fd.text = lines[1..-1]
      # puts Rainbow(File.basename(sf)).cyan
      lines.each do |l|
        next if l =~ /====/
        next if l.strip =~ /^Components:/
        next if l.strip =~ /^Subcomponents:? for/
        if l.strip =~ /^Definition:/
          defn = l.sub(/^\s*Definition:?/, '').strip.gsub(/\n+/, "\n")
          defn = remove_links(defn, section)
          fd.definition_text = defn
          fd.data_element.definition_text = defn
          # puts Rainbow(defn).lightskyblue
          next
        end
        buffer << l
      end
      fd.description = buffer.join("\n").gsub(/\n+/, "\n") unless buffer.reject { |x| x.strip == '' }.empty?
      # puts Rainbow(fd.description).coral
      
    end
    fields
  end
  
  # TODO registering the data element requires the ability to differentiate multiple instances of the same data element
  # This can probably best be acheived by attaching it to the segdef identifier of the field, e.g., MSH-1k
  def process_field_row(line, cols, segment_code, section)
    raw_row = split_row(line)
    # puts line.inspect
    row = cols.map { |c| raw_row[c] }
    seq, len, clen_and_flag, dt, opt, rp, tbl, item_number, name = row
    # tbl = remove_links(tbl, section)
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
