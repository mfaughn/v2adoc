module V2AD

  module_function
  def extract_query_response(original_lines, section, codes, opts = {})
    verbose = opts[:verbose]
    query_code    = codes.shift
    response_code = codes.shift
    raise if codes.any?

    puts Rainbow("Extract query and response events: #{query_code} and #{response_code}").orange if verbose
    lines = original_lines.dup
    l1 = lines.shift
    pair = l1.sub(/^\s*=+\s*\d+\.\d+.\d+\s*/, '').sub(/(-|–).+$/, '').strip
    # puts l1
    if section == '5.4.1'
      names_and_message_types = ['Query by Parameter', 'QBP', 'Segment Pattern Response', 'RSP']
    elsif section == '5.4.3'
      names_and_message_types = ['Query by Parameter', 'QBP', 'Display Response', 'RDY']
    elsif section == '15.3.7'
      names_and_message_types = ['Query by Parameter', 'QBP', 'Segment Pattern Response', 'RSP']      
    else
      names_and_message_types = l1.slice(/(?<=(-|–)).+(?=\([E|e]vent)/).strip.split(' and ').map do |str|
        name = str.slice(/.*(?=\()/).strip
        mt   = str.slice(/(?<=\()[A-Z]{3}(?=\))/).strip
        [name, mt]
      end
    end
    query_name, query_mt, response_name, response_mt = names_and_message_types.flatten
    response_name = query_name + response_name if response_name == 'Response'
    query_mt    = find_or_create_message_type(query_mt, section)
    response_mt = find_or_create_message_type(response_mt, section)
  
    query_event    = V2AD::Event.new(query_code, query_name, section)
    response_event = V2AD::Event.new(response_code, response_name, section)
    # V2AD.add_event(query_event)
    # V2AD.add_event(response_event)
    query_event.section     = section
    query_event.adoc_source = lines
    response_event.section     = section
    response_event.adoc_source = lines
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
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # should we retain the table formatting directive? no....
        table = true
        next
      end
      # $4 is name of message type ????? FIXME applies in all extract_event methods
      if l =~ /([A-Z0-9]{3})\^(#{query_code}|#{response_code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
      elsif l.strip =~ /([A-Z0-9]{3})\^(#{query_code}|#{response_code})\^([A-Z0-9]{3}):\s+.*Acknowledge?ment$/
        # puts Rainbow(l).lawngreen
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
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
          end
          next
        end
        table_buffer << l
      else
        if table_buffer.any?
          key = "#{msg_code}^#{event_code}^#{msg_struct_code}"
          # puts table_buffer
          ttype = "Unknown"
          if is_message_structure_table_header?(table_buffer.first)
            ttype = Rainbow("MSG_STRUCT" ).gold
            tables[key] ||= {}
            tables[key][:message_structure] = table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose
            table_buffer = []
            text_buffer << "\include::message_structure_table_#{key}"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables[key] ||= {}
            tables[key][:ack_chor] = table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose
            table_buffer = []
            text_buffer << "\include::ack_chor_table_#{key}"
            next
          end
          if ttype == "Unknown"
            puts Rainbow(ttype + ' Table Type: ').orange + table_buffer.first.chomp if verbose
            text_buffer += table_buffer
            table_buffer = []
            next
          end
        
          # table_type, processed_table = process_table(table_buffer, section, :msg_struct_code => msg_struct_code)
          # if table_type == :message_structure
          #   text_buffer << '\include::message_structure_table'
          # elsif table_type == :ack_chor
          #   text_buffer << '\include::ack_chor_table'
          # elsif table_type == :other
          #   text_buffer += processed_table
          # else
          #   puts processed_table
          #   raise "Wrong kind of table!! -- #{table_type}"
          # end
          # table_buffer = []
        end
        text_buffer << l
      end
    end
    txt = Text.new(text_buffer, true)
    query_event.text    = txt
    response_event.text = txt
    if tables.size != 2
      pp tables
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section}!").red
      raise tables.keys.inspect
    end
    counter = 0
    trigger_struct, trigger_ac, response_struct, response_ac = nil
    tables.each do |key, tables|
      counter += 1
      # puts key
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      trigger_struct = obj if counter == 1
      response_struct = obj if counter == 2
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      trigger_ac = obj if counter == 1
      response_ac     = obj if counter == 2      
    end
    if response_struct.nil?
      raise "Noooooooo"
    end
  
    trigger_message = query_event.message
    trigger_message.message_type = query_mt
    trigger_message.message_structure = trigger_struct
    trigger_message.ack_chor = trigger_ac
  
    response_msg = response_event.message
    response_msg.message_type = response_mt
    response_msg.message_structure = response_struct
    response_msg.ack_chor          = response_ac
    if tables.keys[1] =~ /ACK/
      trigger_message.ack = response_msg
    else
      trigger_message.add_response(response_msg)
    end
  end
  
  # FIXME this is more or less just a regular event with no explicit ack table....or is it?
  def extract_response(original_lines, section, code, opts = {})
    verbose = opts[:verbose]
    response_code = code

    puts Rainbow("Extract response event: #{response_code}").orange if verbose
    lines = original_lines.dup
    l1 = lines.shift
    pair = l1.sub(/^\s*=+\s*\d+\.\d+.\d+\s*/, '').sub(/(-|–).+$/, '').strip

    response_name = 'Tabular Response'
    response_mt = find_or_create_message_type('RBP', section)
  
    response_event = V2AD::Event.new(response_code, response_name, section)
    # V2AD.add_event(response_event)
    response_event.section     = section
    response_event.adoc_source = lines
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
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # should we retain the table formatting directive? no....
        table = true
        next
      end
      # $4 is name of message type ????? FIXME applies in all extract_event methods
      if l =~ /([A-Z0-9]{3})\^(#{response_code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
      elsif l.strip =~ /([A-Z0-9]{3})\^(#{response_code})\^([A-Z0-9]{3}):\s+.*Acknowledge?ment$/
        # puts Rainbow(l).lawngreen
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
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
          end
          next
        end
        table_buffer << l
      else
        if table_buffer.any?
          key = "#{msg_code}^#{event_code}^#{msg_struct_code}"
          # puts table_buffer
          ttype = "Unknown"
          if is_message_structure_table_header?(table_buffer.first)
            ttype = Rainbow("MSG_STRUCT" ).gold
            tables[key] ||= {}
            tables[key][:message_structure] = table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose
            table_buffer = []
            text_buffer << "\include::message_structure_table_#{key}"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables[key] ||= {}
            tables[key][:ack_chor] = table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose
            table_buffer = []
            text_buffer << "\include::ack_chor_table_#{key}"
            next
          end
          if ttype == "Unknown"
            puts Rainbow(ttype + ' Table Type: ').orange + table_buffer.first.chomp if verbose
            text_buffer += table_buffer
            table_buffer = []
            next
          end
        end
        text_buffer << l
      end
    end
    txt = Text.new(text_buffer, true)
    response_event.text = txt
    if tables.size != 1
      pp tables
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section}!").red
      raise tables.keys.inspect
    end
    counter = 0
    trigger_struct, trigger_ac, response_struct, response_ac = nil
    tables.each do |key, tables|
      counter += 1
      # puts key
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      response_struct = obj if counter == 1
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      response_ac     = obj if counter == 1
    end
    if response_struct.nil?
      raise "Noooooooo"
    end
    
    response_msg = response_event.message
    response_msg.message_type = response_mt
    response_msg.message_structure = response_struct
    response_msg.ack_chor          = response_ac
    
    ack_msg = V2AD::Message.new
    ack_msg.message_type = find_or_create_message_type('ACK', section)
    ack_msg.message_structure = V2AD.general_ack_struct
    ack_msg.ack_chor          = V2AD.general_ack_ac
    
    response_msg.ack = ack_msg
    puts ack_msg.code
    puts ack_msg.message_structure.code
    
  end
end
