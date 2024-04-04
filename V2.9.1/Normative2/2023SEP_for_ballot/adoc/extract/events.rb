module V2AD
  module_function

  def extract_withdrawn_events(lines, section, opts = {})
    l1 = lines.first
    # pp l1
    codes = l1.slice(/(?<=\(Events).+(?=\))/i)&.strip
    codes ||= l1.slice(/(?<=\(Event)\s+[A-Z0-9]{3}(-|–)[A-Z0-9]{3}\s*(?=\))/i)&.strip
    if codes
      puts Rainbow("Multiple withdrawn codes in section #{section}: #{codes}").magenta if opts[:verbose]
      codes.split(/\/|,/).map(&:strip).each { |code| extract_withdrawn_event(lines, section, code) }
      return
    end
    code = l1.slice(/(?<=\(Event).+(?=\))/i)&.strip
    raise "No code for withdrawn event #{lines.first}" unless code
    extract_withdrawn_event(lines, section, code)
  end
  
  def extract_withdrawn_event(lines, section, code, opts = {})
    verbose = opts[:verbose]
    l1 = lines.first
    name = l1.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    raise "No name for withdrawn event #{lines.first} in section #{section}" unless name
    msg_types = l1.slice(/(?<=\d)\s+[A-Z\/]+\s+(?=(-|–))/).strip.split('/')
    event = V2AD::Event.new(code, name, section)
    event.adoc_source = lines
    event.status = 'W'
    event.text = Text.new(lines, true)
    event.message.message_type = find_or_create_message_type(msg_types.first, section)
    puts Rainbow("#{section} Event #{code} - WITHDRAWN: #{msg_types}").cyan if verbose
  end
  
  def extract_events(lines, section, opts = {})
    opts[:verbose] = opts[:verbose] #|| section == '4.6.2'
    verbose = opts[:verbose] 
    return extract_4_4_oddballs(lines, section) if section == '4.4.7.1' || section == '4.4.7.2' || section == '4.4.9.1' || section == '4.4.9.2' || section == '4.4.13.1' || section == '4.4.13.2' || section == '4.4.11.1' || section == '4.4.11.2'
    
    return extract_7_7_1(lines, section, opts) if section == '7.7.1'
    return extract_7_7_2(lines, section, opts) if section == '7.7.2'
    return extract_8_tables(lines, section, opts) if section == '8.11.1'
    return extract_11_4_1(lines, section, opts) if section == '11.4.1'
    return extract_16_3_4(lines, section, opts) if section == '16.3.4'
    return extract_16_3_13(lines, section, opts) if section == '16.3.13'
    return extract_17_6_x(lines, section, opts) if section =~ /17\.6\.(1|2|3|4|5)/
    
    l1 = lines[0]
    codes = l1.slice(/(?<=\([E|e]vents).+(?=\))/)&.strip
    codes ||= l1.slice(/(?<=\([E|e]vent)\s+[A-Z0-9]{3}(-|–)[A-Z0-9]{3}\s*(?=\))/)&.strip
    codes = 'Q25 and K25' if section == '15.3.7'
    if codes
      if codes =~ /[A-Z0-9]{3}(-|–)[A-Z0-9]{3}/
        puts Rainbow("CODES").orange + " #{codes}" if verbose
        if codes == 'M06-M07'
          extract_event(lines, section, 'M06', opts); extract_event(lines, section, 'M07', opts)
        elsif codes == 'C01-C08'
          raise 'Dookie'
          (1..8).each { |r| extract_event(lines, section, 'C0' + r.to_s, opts) }
        elsif codes == 'C09-C12'
          raise 'Dookie'
          extract_event(lines, section, 'C09', opts)
          (10..12).each { |r| extract_event(lines, section, 'C' + r.to_s, opts) }
        end
      elsif codes.split(/,\s*/).size > 1
        return extract_11_6_2(lines) if section == '11.6.2'
        return extract_7_11_1(lines, section, opts) if section == '7.11.1'
        codes = codes.split(/,\s*/)
        codes.each { |c|  extract_event(lines, section, c, opts)}
      elsif codes.split(/\s+and\s+/).size == 2
        codes = codes.split(/\s+and\s+/)
        extract_query_response(lines, section, codes)
      else
        if section == '5.4.1'
          extract_query_response(lines, section, ['Q11', 'K11'])
        elsif section == '5.4.2'
          extract_response(lines, section, 'K13')
        elsif section == '5.4.3'
          extract_query_response(lines, section, ['Q15', 'K15'])
        else
          raise Rainbow("Odd Event Codes in section #{section}! #{codes.inspect}").red
        end
      end
    else
      code = l1.slice(/(?<=\([E|e]vent).+(?=\))/)&.strip
      code ||= l1.slice(/(?<=[R|r]esponse\s\().+(?=\))/)&.strip
      if code
        extract_event(lines, section, code, opts)
      else
        if l1 =~ /4\.4\.1(1|3)\.(1|2)/
          
          extract_event(lines, section, 'O36', opts.merge({:name => 'Laboratory order response message to a single container of a specimen OML - Patient Segments Required'})) if l1 =~ /4\.4\.11\.1/
          extract_event(lines, section, 'O55', opts.merge({:name => 'Laboratory order response message to a single container of a specimen OML - Patient Segments Optional'}))  if l1 =~ /4\.4\.11\.2/
          extract_event(lines, section, 'O40', opts.merge({:name => 'Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Required'}))  if l1 =~ /4\.4\.13\.1/
          extract_event(lines, section, 'O56', opts.merge({:name => 'Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Optional'}))  if l1 =~ /4\.4\.13\.2/
        elsif l1 =~ /4\.4\.9\.(1|2)/
          extract_event(lines, section, 'O34', opts.merge({:name => 'Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Required'}))  if l1 =~ /4\.4\.9\.1/
          extract_event(lines, section, 'O54', opts.merge({:name => 'Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Optional'}))  if l1 =~ /4\.4\.9\.2/
        elsif l1 =~ /4\.6\.2/
          extract_event(lines, section, 'Z73', opts.merge({:name => 'Query Example: Information about Phone Calls'}))
        elsif l1 =~ /4A\.3\.23/
          extract_event(lines, section, 'Q31', opts.merge({:name => 'Query Example: Pharmacy'}))
        elsif l1 =~ /5\.3\.1\.2/
          extract_event(lines, section, 'Z99', opts.merge({:name => 'Query Example: Who Am I'}))
        elsif l1 =~ /5\.3\.2\.3/
          extract_event(lines, section, 'Znn', opts.merge({:name => 'Query Grammer'}))
        elsif l1 =~ /5\.3\.2\.4/
          extract_event(lines, section, 'Znn', opts.merge({:name => 'Response Grammer'}))
        elsif l1 =~ /5\.3\.2\.5/
          extract_event(lines, section, 'Znn', opts.merge({:name => 'Response Grammer for display response Example'}))
        elsif l1 =~ /5\.3\.3\.1/
          extract_event(lines, section, 'Znn', opts.merge({:name => 'Response Grammer with tabular response'}))
        elsif l1 =~ /5\.3\.3\.2/
          extract_event(lines, section, 'Znn', opts.merge({:name => 'Query Profile template for query with segment pattern response'}))
        elsif l1 =~ /5\.3\.3\.3/
          extract_event(lines, section, 'Znn', opts.merge({:name => 'Response Grammer RDY Message'}))
        elsif l1 =~ /5\.7\.3\.1/
          extract_event(lines, section, 'Z83', opts.merge({:name => 'Query Grammer QSB Message Example'}))
        elsif l1 =~ /5\.9\.1\.1\.1/
          extract_event(lines, section, 'Z82', opts.merge({:name => 'Response Grammar Example: Pharmacy Dispense Message'}))
        elsif l1 =~ /5\.9\.1\.2\.1/
          extract_event(lines, section, 'Z85', opts.merge({:name => 'Response Grammar Example: Pharmacy Information Comprehensive'}))
        elsif l1 =~ /5\.9\.2\.1\.1/
          extract_event(lines, section, 'Z87', opts.merge({:name => 'Query Grammar Example: Dispense Information'}))
        elsif l1 =~ /5\.9\.2\.4/
          extract_event(lines, section, 'Z89', opts.merge({:name => 'Query Grammar Example: Lab Results History'}))
        elsif l1 =~ /5\.9\.3\.1\.1/
          extract_event(lines, section, 'Z92', opts.merge({:name => 'Response Grammar Example: Who Am I'}))
        elsif l1 =~ /5\.9\.3\.2\.1/
          extract_event(lines, section, 'Z94', opts.merge({:name => 'Response Grammar Example: Who Am I'}))
        elsif l1 =~ /5\.9\.4\.1\.1/
          extract_event(lines, section, 'Z95', opts.merge({:name => 'Response Grammar Example: Who Am I'}))
        elsif l1 =~ /5\.9\.5\.1/
          extract_event(lines, section, 'Z98', opts.merge({:name => 'Response Grammar Example: Dispense History'}))
        elsif l1 =~ /5\.9\.6\.1/
          extract_event(lines, section, 'Z80', opts.merge({:name => 'Response Grammar Example: Dispense History'}))
        elsif l1 =~ /5\.9\.7\.1/
          extract_event(lines, section, 'Z78', opts.merge({:name => 'Response Grammar Example: TBD'}))
        elsif l1 =~ /5\.9\.7\.2/
          extract_event(lines, section, 'Z76', opts.merge({:name => 'Response Grammar Example: TBD'}))
        else
          raise "Can't find event code in \"#{l1}\""
        end
      end
    end
  end
  
  def extract_event(original_lines, section, code, opts = {})
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.shift
    # pair = l1.sub(/^\s*=+\s*\d+\.\d+.\d+\s*/, '').sub(/(-|–).+$/, '').strip
    name = opts[:name]
    # puts Rainbow(name).lime if name
    name ||= l1.slice(/(?<=(-|–)).+(?=\([E|e]vent)/)&.strip
    name ||= l1.slice(/(?<=(-|–)).+(?=\(...)/)&.strip if l1 =~ /Response \(/
    name ||= l1.slice(/Order Status Update (?=\(Event O51)/)&.strip
    puts Rainbow("#{section} Event #{code}").cyan if verbose
    puts Rainbow("ALERT!").orange + " No name in first line of event section: #{l1}" unless name
    # puts Rainbow(name).orange
    # puts Rainbow(section).green
    # lines.each { |l| puts Rainbow(l).yellow }
    # puts Rainbow('-'*33).orange
    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    msg_struct_code = nil
    msg_code        = nil
    event_code      = nil
    tables = {}
    lines.each_with_index do |l, i|
      puts l if verbose
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # should we retain the table formatting directive? no....
        table = true
        puts Rainbow("table start").blue if verbose
        next
      end

      if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
        unless code == event_code
          puts Rainbow("A. #{code} != #{event_code}").red
          puts l
        end
      elsif l.strip =~ /ACK\^(#{code})\^ACK:/
        # puts Rainbow(l).lawngreen
        msg_code        = 'ACK'
        event_code      = $1
        msg_struct_code = 'ACK'
        unless code == event_code
          puts Rainbow("B. ").red + Rainbow(code).lime + ' != ' + Rainbow(event_code).lime + ' in section ' + Rainbow(section).yellow
          puts l
        end
      elsif l.strip =~ /ACK\^([A-Z0-9]{3}-[A-Z0-9]{3})\^ACK:/ || l.strip =~ /ACK\^(([A-Z0-9]{3},\s?)+[A-Z0-9]{3})\^ACK:/
        msg_code        = 'ACK'
        event_code      = $1
        # event_code      = code
        msg_struct_code = 'ACK'
        event_code = code if event_code =~ /-|,/
        unless code == event_code
          puts Rainbow("C. ").red + Rainbow(code).lime + ' != ' + Rainbow(event_code).lime + ' in section ' + Rainbow(section).yellow
          puts l
        end
        puts Rainbow("Multi ACK ").lawngreen + msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s if verbose
      elsif l.strip =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}):\s+.*(Acknowledge?ment|Response)$/
        puts Rainbow("Weird ACK message? #{l}").lawngreen
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
        unless code == event_code
          puts Rainbow("D. #{code} != #{event_code}").red
          puts l
        end
      elsif l =~ /([A-Z0-9]{3})\^(.+)\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        puts Rainbow($1 + '^' + $2 + '^' + $3).lawngreen + ' any events' if verbose
        puts Rainbow(l).fuchsia if verbose
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
        # puts Rainbow("#{code} != #{event_code}").red unless code == event_code        
        event_code = code if event_code =~ /-|,/
        unless code == event_code || code =~ /(K|Z)../ || code == 'Q31'
          puts Rainbow("E. ").red + Rainbow(code).lime + ' != ' + Rainbow(event_code).lime + ' in section ' + Rainbow(section).yellow
          puts l
        end
      elsif l =~ /(ACK)\^(.+)\^(ACK):\s+(.*)\s*(Message|Description)?/
        raise "Why didn't the block two up from here get this?:\n#{l}"
        msg_code        = 'ACK'
        event_code      = $2
        msg_struct_code = 'ACK'
        # puts Rainbow("#{code} != #{event_code}").red unless code == event_code        
        # event_code = code
        unless code == event_code
          puts Rainbow("F. ").red + Rainbow(code).lime + ' != ' + Rainbow(event_code).lime + ' in section ' + Rainbow(section).yellow
          puts l
        end
      elsif l =~ /([A-Z0-9]{3})\^(.+)\^([A-Z0-9]{3}_[A-Zn0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
        puts Rainbow(l).fuchsia unless l =~ /MFN\^M14\^MFN_Znn/ || l =~ /(RTB|RSP|QBP)\^Znn\^(RTB|RSP|QBP)_(Z|Q|K)nn/
        unless code == event_code
          puts Rainbow("G. ").red + Rainbow(code).lime + ' != ' + Rainbow(event_code).lime + ' in section ' + Rainbow(section).yellow
          puts l
        end
      else
        # puts Rainbow(l).yellow
      end
      #  puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
      
      if table
        if l.strip =~ /\|==+/
          table_mark += 1
          if table_mark > 1
            table = false
            table_mark = 0
            puts Rainbow("table end").blue if verbose
          end
          next
        end
        table_buffer << l
      else
        if table_buffer.any?
          key = "#{msg_code}^#{event_code}^#{msg_struct_code}"
          # puts table_buffer
          ttype = "Unknown"
          if is_message_structure_table_header?(table_buffer.first, verbose)
            ttype = Rainbow("MSG_STRUCT" ).gold
            tables[key] ||= {}
            tables[key][:message_structure] = table_buffer.dup
            puts "#{ttype} -- #{key}" if verbose#: #{table_buffer.first}"
            table_buffer = []
            text_buffer << "\include::message_structure_table_#{key}"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables[key] ||= {}
            tables[key][:ack_chor] = table_buffer.dup
            puts "#{ttype} -- #{key}" if verbose #: #{table_buffer.first}"
            table_buffer = []
            text_buffer << "\include::ack_chor_table_#{key}"
            next
          end
          if ttype == "Unknown"
            puts Rainbow(ttype + ' Table Type: ').magenta + table_buffer.first.chomp if verbose
            text_buffer += table_buffer
            table_buffer = []
            next
          end
        end
        text_buffer << l
      end
    end

    event = V2AD::Event.new(code, name, section)
    response_event = event
    event.adoc_source = lines
    
    # FIXME get the processed text back from the section
    event.text = Text.new(text_buffer, true)
    
    
    # puts '----------------------'
    # puts event.text.lines
    # puts '^^^^^^^^^^^^^^^^^^^^^^'
    
    event_codes = tables.keys.map { |k| k.split('^')[1] }.uniq
    # verbose = true if event_codes.size > 1
    if event_codes.size > 1
      if event_codes.size == 2
        # puts Rainbow("Multiple event codes: #{event_codes}").lime + " in section #{section}"
        response_event = V2AD::Event.new(event_codes.last, name, section)
        response_event.adoc_source = lines
        response_event.text = Text.new(text_buffer, true)
      else
        raise Rainbow("Multiple event codes: #{event_codes}").lime + " in section #{section}"
      end
    end
    
    verbose = true if section == '5.3.2.4'
    if tables.size != 2
      unless \
        section =~ /4\.4\.(1|2)\d/ || 
        section =~ /4\.4\.\d+/ || 
        section == '4.7.1' || 
        section == '4.7.2' || 
        section =~ /4\.10\.\d+/ || 
        section =~ /4\.13\.(2|3|4|5|6|7)/ || 
        section =~ /4\.16\.\d+/ || 
        section =~ /4A\.3\.\d+/ || 
        section == '4A.7.6'  || 
        section =~ /5\.3\.2\.\d/ || 
        section =~ /5\.3\.3\.\d/ || 
        section =~ /5\.7\.3\.1/ || 
        section =~ /^5\.9\.\d\.\d/ || 
        section == '7.16.1'  || 
        section =~ /7\.3\.(1|2)?\d/ ||
        section == '11.6.1' ||
        section == '11.6.6' || 
        section =~ /16\.3\.\d+/
        pp tables
        puts Rainbow("#{tables.size} Weird Event Tables in section #{section}! Code is #{code}").red
        raise tables.keys.inspect
      end
    else
      # puts tables.keys if verbose
    end
    counter = 0
    trigger_struct, trigger_ac, respack_struct, respack_ac = nil
    tables.each do |key, tables|
      counter += 1
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      begin
        _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      rescue
        puts "Section #{section}"
        pp tables
        puts
        lines.each { |l| puts Rainbow(l).yellow }
        raise
      end
      trigger_struct = obj if counter == 1
      respack_struct = obj if counter == 2
      if ack_chor_table
        begin
          _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
        rescue
          puts "Section #{section}"
          pp tables
          puts
          lines.each { |l| puts Rainbow(l).yellow }
          raise
        end
        trigger_ac = obj if counter == 1
        respack_ac = obj if counter == 2
      else
        raise "No ack_chor_table for #{key} in section #{section}" unless section == '5.7.3.1' || section =~ /^5\.9\.\d\.\d/
      end
    end
    if tables.keys[1] =~ /ACK/
      V2AD.general_ack_struct(respack_struct) unless V2AD.general_ack_struct # set general ack struct if it isn't set
      V2AD.general_ack_ac(respack_ac) unless V2AD.general_ack_ac # set general ack ac if it isn't set
    end
    if respack_struct.nil?
      respack_struct = V2AD.general_ack_struct
      respack_ac     = V2AD.general_ack_ac
    end
    trigger_message_type, respack_msg_type = tables.keys.map { |k| k.split('^').first }
    
    trigger_message = event.message
    trigger_message.message_type = find_or_create_message_type(trigger_message_type, section)
    trigger_message.message_structure = trigger_struct
    trigger_message.ack_chor = trigger_ac if trigger_ac
    puts Rainbow("Created message #{trigger_message.code} with message type #{trigger_message.message_type.code}").lime if verbose
    puts "#{trigger_message.message_type.code} messages are: #{trigger_message.message_type.messages.map(&:code)}" if verbose
    # puts "Message struct is #{trigger_struct.code}" if verbose
    
    
    if respack_msg_type
      if event == response_event
        if tables.keys[1] =~ /ACK/
          respack_msg = create_ack_message(trigger_message)
        else
          respack_msg = create_response_message(trigger_message)
        end
      else
        respack_msg = response_event.message # because this message was automatically created when we created the response event
      end
      respack_msg.message_type = find_or_create_message_type(respack_msg_type, section)
      respack_msg.message_structure = respack_struct
      respack_msg.ack_chor          = respack_ac if respack_ac
      puts "Message struct is #{trigger_struct.code}" if verbose
      puts "Response struct is #{respack_struct.code}" if verbose
      puts "Created message #{respack_msg.code}" if verbose
      # puts "#{respack_msg.code} has type #{respack_msg.message_type.code}"
    end
  end
  
  def extract_undefined_event(original_lines, section, opts = {})
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.first
    name = l1.slice(/(?<=(-|–)).+(?=\([E|e]vent)/)&.strip
    code = l1.slice(/(?<=\([E|e]vent).+(?=\))/)&.strip
    puts Rainbow("#{section} Event #{code}").cyan if verbose
    puts Rainbow("ALERT!").orange + " No name in first line of event section: #{l1}" unless name
  
    event = V2AD::Event.new(code, name, section)
   # V2AD.add_event(event)
    event.section        = section
    event.adoc_source    = lines
    event.text           = Text.new(['Not yet defined.'])
  end

  
  def find_or_create_message_type(code, section, name = nil)
    mt = V2AD.v2.message_types[code]
    mt ||= V2AD::MessageType.new(code, section)
    if name
      if mt.name
        if mt.name != name
          raise "MessageType #{code} conflicting name: has - #{mt.name}; given: #{name}" 
        end
      else
        mt.name = name
      end
    end
    raise "Shucks" if mt.is_a?(String)
    mt
  end
end  
