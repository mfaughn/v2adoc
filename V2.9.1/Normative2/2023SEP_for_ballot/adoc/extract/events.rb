module V2AD
  module_function

  def extract_withdrawn_events(section, opts = {})
    ttl = section.title
    # pp ttl
    codes = ttl.slice(/(?<=\(Events).+(?=\))/i)&.strip
    codes ||= ttl.slice(/(?<=\(Event)\s+[A-Z0-9]{3}(-|–)[A-Z0-9]{3}\s*(?=\))/i)&.strip
    if codes
      puts Rainbow("Multiple withdrawn codes in section #{section.num}: #{codes}").magenta if opts[:verbose]
      codes.split(/\/|,/).map(&:strip).each { |code| extract_withdrawn_event(section, code) }
      return
    end
    code = ttl.slice(/(?<=\(Event).+(?=\))/i)&.strip
    raise "No code for withdrawn event #{lines.first}" unless code
    extract_withdrawn_event(section, code)
  end
  
  def extract_withdrawn_event(section, code, opts = {})
    verbose = opts[:verbose] #|| true
    st = section.title
    name = st.slice(/.+(?=\(Event)/)&.strip
    raise "No name for withdrawn event #{st} in section #{section.num}" unless name
    substr = st.slice(/[A-Z\/]+\s+(?=(-|–))/)
    msg_types = substr&.gsub(/-|–/, '')&.strip&.split('/')
    unless msg_types
      section.display
      raise "No message types for withdrawn event"
    end
    event = V2AD::Event.new(code, name, section)
    event.status = 'W'
    event.message.message_type = find_or_create_message_type(msg_types.first, section)
    puts Rainbow("#{section.num} Event #{code} - WITHDRAWN: #{msg_types}").cyan if verbose
  end
  
  def extract_events(section, opts = {})
    section_num = section.num
    opts[:verbose] = opts[:verbose] #|| section_num == '4.6.2'
    verbose = opts[:verbose] 
    
    if ['4.4.7.1', '4.4.7.2', '4.4.9.1', '4.4.9.2','4.4.13.1', '4.4.13.2', '4.4.11.1', '4.4.11.2'].include?(section_num)
      return extract_4_4_oddballs(section)
    end
    
    return extract_7_7_1(section, opts)    if section_num == '7.7.1'
    return extract_7_7_2(section, opts)    if section_num == '7.7.2'
    return extract_8_11(section, opts) if section_num == '8.11.1'
    return extract_11_4_1(section, opts)   if section_num == '11.4.1' # This has the msg struct and ac for 11.4.2-11.4.5
    return extract_16_3_4(section, opts)   if section_num == '16.3.4'
    return extract_16_3_13(section, opts)  if section_num == '16.3.13'
    return extract_17_6_x(section, opts)   if section_num =~ /17\.6\.(1|2|3|4|5)/
    
    ttl = section.title
    codes = ttl.slice(/(?<=\([E|e]vents).+(?=\))/)&.strip
    codes ||= ttl.slice(/(?<=\([E|e]vent)\s+[A-Z0-9]{3}(-|–)[A-Z0-9]{3}\s*(?=\))/)&.strip
    codes = 'Q25 and K25' if section_num == '15.3.7'
    if codes
      if codes =~ /[A-Z0-9]{3}(-|–)[A-Z0-9]{3}/
        puts Rainbow("CODES").orange + " #{codes}" if verbose
        if codes == 'M06-M07'
          extract_event(section, 'M06', opts); extract_event(section, 'M07', opts)
        elsif codes == 'C01-C08'
          raise 'Dookie'
          (1..8).each { |r| extract_event(section, 'C0' + r.to_s, opts) }
        elsif codes == 'C09-C12'
          raise 'Dookie'
          extract_event(section, 'C09', opts)
          (10..12).each { |r| extract_event(section, 'C' + r.to_s, opts) }
        end
      elsif codes.split(/,\s*/).size > 1
        return extract_11_6_2(section)       if section_num == '11.6.2'
        return extract_7_11_1(section, opts) if section_num == '7.11.1'
        codes = codes.split(/,\s*/)
        codes.each { |c|  extract_event(section, c, opts)}
      elsif codes.split(/\s+and\s+/).size == 2
        codes = codes.split(/\s+and\s+/)
        extract_query_response(section, codes)
      else
        if section_num == '5.4.1'
          extract_query_response(section, ['Q11', 'K11'])
        elsif section_num == '5.4.2'
          extract_response(section, 'K13')
        elsif section_num == '5.4.3'
          extract_query_response(section, ['Q15', 'K15'])
        else
          raise Rainbow("Odd Event Codes in section #{section_num}! #{codes.inspect}").red
        end
      end
    else
      code = ttl.slice(/(?<=\([E|e]vent).+(?=\))/)&.strip
      code ||= ttl.slice(/(?<=[R|r]esponse\s\().+(?=\))/)&.strip
      if code
        extract_event(section, code, opts)
      else
        if section_num =~ /4\.4\.1(1|3)\.(1|2)/
          
          extract_event(section, 'O36', opts.merge({:name => 'Laboratory order response message to a single container of a specimen OML - Patient Segments Required'})) if section_num =~ /4\.4\.11\.1/
          extract_event(section, 'O55', opts.merge({:name => 'Laboratory order response message to a single container of a specimen OML - Patient Segments Optional'}))  if section_num =~ /4\.4\.11\.2/
          extract_event(section, 'O40', opts.merge({:name => 'Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Required'}))  if section_num =~ /4\.4\.13\.1/
          extract_event(section, 'O56', opts.merge({:name => 'Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Optional'}))  if section_num =~ /4\.4\.13\.2/
        elsif section_num =~ /4\.4\.9\.(1|2)/
          extract_event(section, 'O34', opts.merge({:name => 'Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Required'}))  if section_num =~ /4\.4\.9\.1/
          extract_event(section, 'O54', opts.merge({:name => 'Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Optional'}))  if section_num =~ /4\.4\.9\.2/
        elsif section_num =~ /4\.6\.2/
          extract_event(section, 'Z73', opts.merge({:name => 'Query Example: Information about Phone Calls'}))
        elsif section_num =~ /4A\.3\.23/
          extract_event(section, 'Q31', opts.merge({:name => 'Query Example: Pharmacy'}))
        elsif section_num =~ /5\.3\.1\.2/
          extract_event(section, 'Z99', opts.merge({:name => 'Query Example: Who Am I'}))
        elsif section_num =~ /5\.3\.2\.3/
          extract_event(section, 'Znn', opts.merge({:name => 'Query Grammer'}))
        elsif section_num =~ /5\.3\.2\.4/
          extract_event(section, 'Znn', opts.merge({:name => 'Response Grammer'}))
        elsif section_num =~ /5\.3\.2\.5/
          extract_event(section, 'Znn', opts.merge({:name => 'Response Grammer for display response Example'}))
        elsif section_num =~ /5\.3\.3\.1/
          extract_event(section, 'Znn', opts.merge({:name => 'Response Grammer with tabular response'}))
        elsif section_num =~ /5\.3\.3\.2/
          extract_event(section, 'Znn', opts.merge({:name => 'Query Profile template for query with segment pattern response'}))
        elsif section_num =~ /5\.3\.3\.3/
          extract_event(section, 'Znn', opts.merge({:name => 'Response Grammer RDY Message'}))
        elsif section_num =~ /5\.7\.3\.1/
          extract_event(section, 'Z83', opts.merge({:name => 'Query Grammer QSB Message Example'}))
        elsif section_num =~ /5\.9\.1\.1\.1/
          extract_event(section, 'Z82', opts.merge({:name => 'Response Grammar Example: Pharmacy Dispense Message'}))
        elsif section_num =~ /5\.9\.1\.2\.1/
          extract_event(section, 'Z85', opts.merge({:name => 'Response Grammar Example: Pharmacy Information Comprehensive'}))
        elsif section_num =~ /5\.9\.2\.1\.1/
          extract_event(section, 'Z87', opts.merge({:name => 'Query Grammar Example: Dispense Information'}))
        elsif section_num =~ /5\.9\.2\.4/
          extract_event(section, 'Z89', opts.merge({:name => 'Query Grammar Example: Lab Results History'}))
        elsif section_num =~ /5\.9\.3\.1\.1/
          extract_event(section, 'Z92', opts.merge({:name => 'Response Grammar Example: Who Am I'}))
        elsif section_num =~ /5\.9\.3\.2\.1/
          extract_event(section, 'Z94', opts.merge({:name => 'Response Grammar Example: Who Am I'}))
        elsif section_num =~ /5\.9\.4\.1\.1/
          extract_event(section, 'Z95', opts.merge({:name => 'Response Grammar Example: Who Am I'}))
        elsif section_num =~ /5\.9\.5\.1/
          extract_event(section, 'Z98', opts.merge({:name => 'Response Grammar Example: Dispense History'}))
        elsif section_num =~ /5\.9\.6\.1/
          extract_event(section, 'Z80', opts.merge({:name => 'Response Grammar Example: Dispense History'}))
        elsif section_num =~ /5\.9\.7\.1/
          extract_event(section, 'Z78', opts.merge({:name => 'Response Grammar Example: TBD'}))
        elsif section_num =~ /5\.9\.7\.2/
          extract_event(section, 'Z76', opts.merge({:name => 'Response Grammar Example: TBD'}))
        else
          section.display
          raise "Can't find event code in \"#{ttl}\""
        end
      end
    end
  end
  
  def extract_event(section, code, opts = {})
    section_num = section.num
    verbose     = opts[:verbose] || section_num == '3.3.56'
    verbose = true if section_num == '5.3.2.4'
    name = opts[:name]
    ttl = section.title
    # puts Rainbow(name).lime if name
    name ||= ttl.slice(/(?<=(-|–)).+(?=\([E|e]vent)/)&.strip
    name ||= ttl.slice(/(?<=(-|–)).+(?=\(...)/)&.strip if section_num =~ /Response \(/
    name ||= ttl.slice(/Order Status Update (?=\(Event O51)/)&.strip
    
    puts Rainbow("#{section_num} Event #{code}").cyan if verbose
    puts Rainbow("ALERT!").orange + " No name in title of event section #{section_num}: #{section.title}" unless name
    # puts Rainbow(name).orange
    # puts Rainbow(section_num).green

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    
    trig_msg_type, trigger_struct, trigger_ac, respack_msg_type, respack_struct, respack_ac, event_codes = process_event_section_tables(section, verbose:verbose, tables:tables)
    if code.to_s =~ /nil|null/i
      puts caller
      raise "Culprit: #{section_num}. Code is #{code.inspect}" 
    end
    event = V2AD::Event.new(code, name, section) # do we want to use code or event_code ?? TODO
    response_event = event # why do this? Because this just indicates that the response message is grouped with the trigger event message.
    if event_codes.size > 1
      # verbose = true
      # raise "Multiple event codes in section #{section_num}: #{event_codes}"
      if event_codes.size == 2
        # puts Rainbow("Multiple event codes: #{event_codes}").lime + " in section #{section_num}"
        response_event = V2AD::Event.new(event_codes.last, name, section)
      else
        raise Rainbow("Multiple event codes: #{event_codes}").lime + " in section #{section_num}"
      end
    end
    
    if tables.size != 4
      unless \
        section_num =~ /4\.4\.(1|2)\d/ || 
        section_num =~ /4\.4\.\d+/ || 
        section_num == '4.7.1' || 
        section_num == '4.7.2' || 
        section_num =~ /4\.10\.\d+/ || 
        section_num =~ /4\.13\.(2|3|4|5|6|7)/ || 
        section_num =~ /4\.16\.\d+/ || 
        section_num =~ /4A\.3\.\d+/ || 
        section_num == '4A.7.6'  || 
        section_num =~ /5\.3\.2\.\d/ || 
        section_num =~ /5\.3\.3\.\d/ || 
        section_num =~ /5\.7\.3\.1/ || 
        section_num =~ /^5\.9\.\d\.\d/ || 
        section_num == '7.16.1'  || 
        section_num =~ /7\.3\.(1|2)?\d/ ||
        section_num == '11.6.1' ||
        section_num == '11.6.6' || 
        section_num =~ /16\.3\.\d+/
        pp tables
        puts Rainbow("#{tables.size} Weird Event Tables in section #{section_num}! Code is #{code}").red
        tables.each(:display)
        raise
      end
    else
      # tables.each(:display) if verbose
    end

    if respack_struct && !respack_ac
      raise "No ack_chor_table for #{key} in section #{section_num}" unless section_num == '5.7.3.1' || section_num =~ /^5\.9\.\d\.\d/
    end

    unless V2AD.general_ack_struct # set general ack struct if it isn't set
      V2AD.general_ack_struct(respack_struct) if tables.find { |tbl| tbl.type == :ack_message_structure }
    end
    unless V2AD.general_ack_ac # set general ack ac if it isn't set
      V2AD.general_ack_ac(respack_ac) if tables.find { |tbl| tbl.type == :ack_message_structure }
    end
    
    if respack_struct.nil?
      respack_struct = V2AD.general_ack_struct
      respack_ac     = V2AD.general_ack_ac
    end
    
    trig_msg                   = event.message
    trig_msg.message_type      = find_or_create_message_type(trig_msg_type, section)
    trig_msg.message_structure = trigger_struct
    trig_msg.ack_chor          = trigger_ac if trigger_ac
    puts Rainbow("Created message #{trig_msg.code} with message type #{trig_msg.message_type.code}").lime if verbose
    puts "#{trig_msg.message_type.code} messages are: #{trig_msg.message_type.messages.map(&:code)}" if verbose
    # puts "Message struct is #{trigger_struct.code}" if verbose
  
    
    if respack_msg_type
      if event == response_event
        if respack_msg_type =~ /ACK/
          respack_msg = create_ack_message(trig_msg, true)
        else
          respack_msg = create_response_message(trig_msg)
        end
      else
        respack_msg = response_event.message # because this message was automatically created when we created the response event
        trig_msg.add_response(respack_msg)
      end
      
      respack_msg.message_type      ||= find_or_create_message_type(respack_msg_type, section)
      respack_msg.message_structure ||= respack_struct
      respack_msg.ack_chor          ||= respack_ac if respack_ac
      puts "Message struct is #{trigger_struct.code}"  if verbose
      puts "Response struct is #{respack_struct.code}" if verbose
      puts "Created message #{respack_msg.code}"       if verbose
      # puts "#{respack_msg.code} has type #{respack_msg.message_type.code}"
    end
    # if section_num == '3.3.1'
    #   # puts event.message.trigger
    #   # puts respack_msg.message_type.code
    #   puts "trig_msg"
    #   puts trig_msg.message_type.code
    #   puts trig_msg
    #   puts "trig_msg ack"
    #   puts trig_msg.ack.message_type.code
    #   puts trig_msg.ack
    #   puts "respack_msg.ack_to"
    #   puts respack_msg.ack_to.map { |x| x.message_type.code }
    #   puts respack_msg.ack_to
    #   puts "respack_msg"
    #   puts respack_msg.message_type.code
    #   puts respack_msg
    # end
    event
  end

  def extract_undefined_event(section, opts = {})
    verbose = opts[:verbose]
    ttl = section.title
    name = ttl.slice(/(?<=(-|–)).+(?=\([E|e]vent)/)&.strip
    code = ttl.slice(/(?<=\([E|e]vent).+(?=\))/)&.strip
    puts Rainbow("#{section.num} Event #{code}").cyan if verbose
    puts Rainbow("ALERT!").orange + " No name in title of event section: #{ttl}" unless name
  
    event = V2AD::Event.new(code, name, section)
    event.section        = section
  end

  def find_or_create_message_type(code, section, name = nil)
    unless code
      section.display
      pp section
      raise "No code"
    end
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
  
  def process_event_section_tables(section, opts = {})
    verbose = opts[:verbose]
    tables  = opts[:tables] || section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    
    event_codes = []
    trigger_struct, trigger_ac, respack_struct, respack_ac = nil
    trig_msg_type, respack_msg_type                 = nil
    tables.each_with_index do |table, i|
      table.display(:coral) if verbose
    
      if [:message_structure, :ack_message_structure, :query_message_structure, :response_message_structure].include?(table.type)
        codes = table.get_message_codes_from_caption
        raise "abnormal codes from #{table.caption || table.possible_caption} -- #{codes.inspect}" unless codes.size == 3
        msg_code, event_code, msg_struct_code = codes
        # puts Rainbow([msg_code, event_code, msg_struct_code].inspect).green
        puts Rainbow([msg_code, event_code, msg_struct_code].inspect).red if event_code =~ /[-,;]/ # FIXME raise here or handle it
        # FIXME finish what happens in here
        
        # check if passed parameter @code == event_code ?
        
        event_codes << event_code unless event_codes.include?(event_code)
        
        obj = process_msg_structure_table(table, section, :msg_struct_code => msg_struct_code)
        
        if i < 1
          trigger_struct = obj
          trig_msg_type = msg_code
        else
          respack_struct = obj
          respack_msg_type = msg_code
        end
      elsif table.type == :ack_chor
        obj = process_ack_chor_table(table, section)
        if i < 2
          trigger_ac = obj
        else
          respack_ac = obj
        end
      else
        raise "Unknown table type #{table.type}"
      end
    end
    [trig_msg_type, trigger_struct, trigger_ac, respack_msg_type, respack_struct, respack_ac, event_codes]
  end
end  
