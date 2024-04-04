module V2AD
  module_function

  def extract_7_7_1(original_lines, section, opts = {})
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.shift
    codes = (1..8).map { |n| 'C' + n.to_s.rjust(2,'0') }
    names = [
      'Register a patient on a clinical trial',
      'Cancel a patient registration on clinical trial (for clerical mistakes since an intended registration should not be canceled)',
      'Correct/update registration information',
      'Patient has gone off a clinical trial',
      'Patient enters phase of clinical trial',
      'Cancel patient entering a phase (clerical mistake)',
      'Correct/update phase information',
      'Patient has gone off phase of clinical trial'
    ]
    codes_and_names = codes.zip(names)
    events = codes_and_names.map do |c,n|
      e = V2AD::Event.new(c, n, section)
      e.adoc_source = lines
      e
    end
    puts Rainbow("#{section} Events C01-C08").cyan if verbose
        
    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    msg_struct_code = nil
    msg_code        = nil
    event_code      = nil
    tables = []
    ack_counter = 0
    lines.each_with_index do |l, i|
      # puts Rainbow(l).magenta
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # should we retain the table formatting directive? no....
        table = true
        next
      end
      if l =~ /CRM\^(C01-C08)\^CRM_C01:\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = 'CRM'
        event_code      = $1
        msg_struct_code = 'CRM_C01'
         puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
        puts Rainbow("C01-C08 != #{event_code}").red unless 'C01-C08' == event_code
      elsif l.strip =~ /ACK\^(C0\d)\^ACK:\s+.*(Acknowledge?ment|Response)$/
        # puts Rainbow(l).lawngreen
        msg_code        = 'ACK'
        event_code      = $1
        msg_struct_code = 'ACK'
         puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
        puts Rainbow("ACK for C01-C08 != #{event_code}").red unless event_code =~ /C0\d/
      end
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
          # puts table_buffer
          ttype = "Unknown"
          if is_message_structure_table_header?(table_buffer.first)
            ttype = Rainbow("MSG_STRUCT" ).gold
            tables << table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose
            table_buffer = []
            text_buffer << "\include::message_structure_table_CRM^C01-C08^CRM_C01"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ack_counter += 1
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables << table_buffer.dup
            puts "#{ttype} -- #{msg_code}^C0#{ack_counter}^#{msg_struct_code}" if verbose #: #{table_buffer.first}"
            table_buffer = []
            text_buffer << "\include::ack_chor_table_CRM^C0#{ack_counter}^CRM_C01"
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
    events.each { |e| e.text = txt }
    if tables.size != 9
      pp tables
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section}!").red
      raise "Fudge..."
    end
    _, crm_co1_struct = process_table(tables.shift, section, :msg_struct_code => 'CRM_C01')
    ack_chors = (1..8).map { |n| process_table(tables.shift, section, :msg_struct_code => 'CRM_C01').last }

    crm = find_or_create_message_type('CRM', section, 'Clinical Study Registration')
    messages = events.map(&:message)
    ack_type = find_or_create_message_type('ACK', section)
    ack_messages = (1..8).map do
      am = V2AD::Message.new
      am.message_type      = ack_type
      am.message_structure = V2AD.general_ack_struct
      am.ack_chor          = V2AD.general_ack_ac
      am
    end
    
    messages.each_with_index do |m, i|
      m.message_type      = crm
      m.message_structure = crm_co1_struct
      m.ack_chor          = ack_chors[i]
      m.ack               = ack_messages[i]
    end    
  end
  
  def extract_7_7_2(original_lines, section, opts = {})
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.shift
    event_range = (9..12)
    codes = event_range.map { |n| 'C' + n.to_s.rjust(2,'0') }
    names = [
      'Automated time intervals for reporting, like monthly',
      'Patient completes the clinical trial',
      'Patient completes a phase of the clinical trial',
      'Update/correction of patient order/result information'
    ]
    codes_and_names = codes.zip(names)
    events = codes_and_names.map do |c,n|
      e = V2AD::Event.new(c, n, section)
      # # V2AD.add_event(event).V2AD(event)[c] = e
      e.adoc_source = lines
      e
    end
    puts Rainbow("#{section} Events C09-C12").cyan if verbose

    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    msg_struct_code = nil
    msg_code        = nil
    event_code      = nil
    tables = []
    ack_counter = 8
    lines.each_with_index do |l, i|
      # puts Rainbow(l).magenta
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # should we retain the table formatting directive? no....
        table = true
        next
      end
      if l =~ /CSU\^(C09-C12)\^CSU_C09:\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = 'CSU'
        event_code      = $1
        msg_struct_code = 'CSU_C09'
        puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
        puts Rainbow("C09-C12 != #{event_code}").red unless 'C09-C12' == event_code
      elsif l.strip =~ /ACK\^(C0\d)\^ACK:\s+.*(Acknowledge?ment|Response)$/
        # puts Rainbow(l).lawngreen
        msg_code        = 'ACK'
        event_code      = $1
        msg_struct_code = 'ACK'
        puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
        puts Rainbow("ACK for C09-C12 != #{event_code}").red unless event_code =~ /C(0|1)\d/
      end
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
          # puts table_buffer
          ttype = "Unknown"
          if is_message_structure_table_header?(table_buffer.first)
            ttype = Rainbow("MSG_STRUCT" ).gold
            tables << table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose
            table_buffer = []
            text_buffer << "\include::message_structure_table_CRM^C09-C12^CRM_C01"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ack_counter += 1
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables << table_buffer.dup
            puts "#{ttype} -- #{msg_code}^C#{ack_counter.to_s.rjust(2,'0')}^#{msg_struct_code}" if verbose#: #{table_buffer.first}"
            table_buffer = []
            text_buffer << "\include::ack_chor_table_CRM^CC#{ack_counter.to_s.rjust(2,'0')}^CRM_C01"
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
    events.each { |e| e.text = txt }
    if tables.size != 5
      pp tables
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section}!").red
      raise "Fudge..."
    end
    _, trigger_struct = process_table(tables.shift, section, :msg_struct_code => 'CSU_C09')
    ack_chors = event_range.map { |n| process_table(tables.shift, section, :msg_struct_code => 'CSU_C09').last }

    crm = find_or_create_message_type('CSU', section, 'Unsolicited Study Data')
    messages = events.map(&:message)
    ack_type = find_or_create_message_type('ACK', section)
    ack_messages = event_range.map do
      am                   = V2AD::Message.new
      am.message_type      = ack_type
      am.message_structure = V2AD.general_ack_struct
      am.ack_chor          = V2AD.general_ack_ac
      am
    end
    
    messages.each_with_index do |m, i|
      m.message_type      = crm
      m.message_structure = trigger_struct
      m.ack_chor          = ack_chors[i]
      m.ack               = ack_messages[i]
    end    
  end
  
  def extract_7_11_1(original_lines, section, opts = {})
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.shift
    p07code = 'P07'
    p08code = 'P08'    
    p07name = 'Unsolicited initial individual product experience report'
    p08name = 'Unsolicited update individual product experience report'
    puts Rainbow("#{section} Event P07, P08").cyan if verbose
    event07 = V2AD::Event.new(p07code, p07name, section)
    event08 = V2AD::Event.new(p08code, p08name, section)
    event07.adoc_source = event08.adoc_source = lines
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
    tables = []
    lines.each_with_index do |l, i|
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # should we retain the table formatting directive? no....
        table = true
        next
      end
      if l =~ /([A-Z0-9]{3})\^(P07-P08)\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
         puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
        puts Rainbow("P07-P08 != #{event_code}").red unless 'P07-P08' == event_code
      elsif l.strip =~ /([A-Z0-9]{3})\^(P07|P08)\^([A-Z0-9]{3}):\s+.*(Acknowledge?ment|Response)$/
        # puts Rainbow(l).lawngreen
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
         puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
        puts Rainbow("ACK for P07-P08 != #{event_code}").red unless 'P07' == event_code || 'P08' == event_code
      end
      
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
            tables << table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose
            table_buffer = []
            text_buffer << "\include::message_structure_table_#{key}"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables << table_buffer.dup
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
    event07.text = event08.text = Text.new(text_buffer, true)
    if tables.size != 3
      pp tables
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section}!").red
      raise tables.keys.inspect
    end
    _, pex_p07_struct = process_table(tables.shift, section, :msg_struct_code => 'PEX_P07')
    _, ac_07          = process_table(tables.shift, section, :msg_struct_code => 'PEX_P07')
    _, ac_08          = process_table(tables.shift, section, :msg_struct_code => 'PEX_P07')

    pex = find_or_create_message_type('PEX', section)
    
    p07_message = event07.message
    p08_message = event08.message
    p07_message.message_type = pex
    p08_message.message_type = pex
    p07_message.message_structure = pex_p07_struct
    p08_message.message_structure = pex_p07_struct
    p07_message.ack_chor = ac_07
    p08_message.ack_chor = ac_08
    
    ack07_msg = create_ack_message(p07_message)
    ack08_msg = create_ack_message(p08_message)
    ack07_msg.message_type = find_or_create_message_type('ACK', section)
    ack08_msg.message_type = find_or_create_message_type('ACK', section)
    ack07_msg.message_structure = V2AD.general_ack_struct
    ack08_msg.message_structure = V2AD.general_ack_struct
    ack07_msg.ack_chor = V2AD.general_ack_ac
    ack08_msg.ack_chor = V2AD.general_ack_ac
  end
  
  def extract_4_4_oddballs(original_lines, section, opts = {})
    verbose = opts[:verbose]
    if section == '4.4.7.1'
      code = 'O22'
      name = "General Laboratory Order Acknowledgment Message - Patient Segments Required"
    elsif section == '4.4.7.2'
      code = 'O53'
      name = "General Laboratory Order Acknowledgment Message - Patient Segments Optional"
    elsif section == '4.4.9.1'
      code = 'O34'
      name = "Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Required"
    elsif section == '4.4.9.2'
      code = 'O54'
      name = "Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Optional"
    elsif section == '4.4.11.1'
      code = 'O36'
      name = "Laboratory order response message to a single container of a specimen OML - Patient Segments Required"
    elsif section == '4.4.11.2'
      code = 'O55'
      name = "Laboratory order response message to a single container of a specimen OML - Patient Segments Optional"
    elsif section == '4.4.13.1'
      code = 'O40'
      name = "Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Required"
    elsif section == '4.4.13.2'
      code = 'O56'
      name = "Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Optional"
    else
      raise "WTF?"
    end
    lines = original_lines.dup
    l1 = lines.shift
    puts Rainbow("#{section} Event #{code}").cyan if verbose

    event = V2AD::Event.new(code, name, section)
    event.adoc_source = lines

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

      if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
        puts Rainbow("#{code} != #{event_code}").red unless code == event_code
      elsif l.strip =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}):\s+.*(Acknowledge?ment|Response)$/
        # puts Rainbow(l).lawngreen
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
        puts Rainbow("#{code} != #{event_code}").red unless code == event_code
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
    event.text = Text.new(text_buffer, true)
    if tables.size != 1
      pp tables
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section}!").red
      raise tables.keys.inspect
    end
    counter = 0
    trigger_struct, trigger_ac, ack_struct, ack_ac = nil
    tables.each do |key, tables|
      counter += 1
      # puts key
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      trigger_struct = obj if counter == 1
      ack_struct = obj if counter == 2
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      trigger_ac = obj if counter == 1
      ack_ac     = obj if counter == 2      
    end
    if ack_struct.nil?
      ack_struct = V2AD.general_ack_struct
      ack_ac     = V2AD.general_ack_ac
    end
    
    trigger_message_type, ack_msg_type = tables.keys.map { |k| k.split('^').first }
    
    trigger_message = event.message
    trigger_message.message_type = find_or_create_message_type(trigger_message_type, section)
    trigger_message.message_structure = trigger_struct
    trigger_message.ack_chor = trigger_ac
    
    if ack_msg_type
      ack_msg = create_ack_message(trigger_message)
      ack_msg.message_type      = find_or_create_message_type(ack_msg_type, section)
      ack_msg.message_structure = ack_struct
      ack_msg.ack_chor          = ack_ac
    end
  end
    
  def extract_10_3(original_lines, opts = {})
    verbose = opts[:verbose]
    section = '10.3'
    lines = original_lines.dup
    tables = []
    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    lines.each_with_index do |l, i|
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # FIXME should we retain the table formatting directive?
        table = true
      else
        if l.strip =~ /(SRM)\^(S01-S11)\^(SRM_S01): Schedule Request Message/
          msg_code        = 'SRM'
          msg_struct_code = 'SRM_S01'
        elsif l.strip =~ /(SRR)\^(S01-S11)\^(SRR_S01): Scheduled Request Response/
          msg_code        = 'SRR'
          msg_struct_code = 'SRR_S01'
        end

        if table
          if l.strip =~ /\|==+/
            table_mark += 1
            if table_mark > 1
              table = false
              table_mark = 0
              tables << table_buffer.dup
              table_buffer = []
            end
            next
          end
          table_buffer << l
        end
      end
    end
    trigger_struct, trigger_ac, response_struct, response_ac = nil
    # pp tables; raise
    # puts
    trigger_struct_table, trigger_ac_table, resp_struct_table, resp_ac_table = tables
    _, trigger_struct = process_table(trigger_struct_table, '10.3', :msg_struct_code => 'SRM_S01')
    _, response_struct = process_table(resp_struct_table, '10.3', :msg_struct_code => 'SRR_S01')

    event_codes  = (1..11).map { |x| 'S' + x.to_s.rjust(2, '0') }

    event_codes.each_with_index do |ec, i|
      sec = "#{section}.#{i+1}"
      event = V2AD::Event.new(ec, nil, sec)
      puts "Created event #{event.code} for section #{sec}" if verbose
      trigger_msg = event.message
      
      trigger_msg.message_type = find_or_create_message_type('SRM', section)
      
      trigger_msg.message_structure = trigger_struct
      
      response_message                   = create_response_message(trigger_msg)
      response_message.message_type      = find_or_create_message_type('SRR', section)
      response_message.message_structure = response_struct
      
      tact = trigger_ac_table.dup.map { |l| l.gsub('S01-S11', ec) }
      _, trig_ac = process_table(tact, '10.3', :msg_struct_code => 'SRM_S01')
      ract = resp_ac_table.dup.map { |l| l.gsub('S10-S11', ec)} # note that S10-S11 is what is in the text but is wrong and should've been S01-S11
      _, resp_ac = process_table(ract, '10.3', :msg_struct_code => 'SRR_S01')

      trigger_msg.ack_chor      = trig_ac
      response_message.ack_chor = resp_ac
    end
  end
  
  def extract_event_ch10(lines, section, opts = {})
    l1 = lines[0]
    # puts l1
    code = l1.slice(/(?<=\(Event).+(?=\))/)&.strip
    name = l1.slice(/(?<=10\.\d\.\d)(?:\d)?.+(?=\(Event)/).strip.sub(/^\d*\s*/, '')
    # puts Rainbow(section).coral + " #{name} (Event #{code})"
    # event = V2AD::Event.new(code, name, section)
    event = V2AD.v2.events[code].find { |e| e.section == section }
    raise 'No event' unless event
    event.adoc_source = lines
    event.text = Text.new(lines, true)
  end

  def extract_10_4(original_lines, opts = {})
    lines = original_lines.dup
    tables = []
    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    lines.each_with_index do |l, i|
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # FIXME should we retain the table formatting directive?
        table = true
      else
        if l.strip =~ /(SIU)\^(S12-S24,S26,S27)\^(SIU_S12): Schedule Request Message/
          msg_code        = 'SIU'
          msg_struct_code = 'SIU_S12'
        elsif l.strip =~ /(ACK)\^(S12-S24,S26,S27)\^(ACK): Scheduled Request Response/
          msg_code        = 'ACK'
          msg_struct_code = 'ACK'
        end

        if table
          if l.strip =~ /\|==+/
            table_mark += 1
            if table_mark > 1
              table = false
              table_mark = 0
              tables << table_buffer.dup
              table_buffer = []
            end
            next
          end
          table_buffer << l
        end
      end
    end
    trigger_struct_table, trigger_ac_table, ack_struct_table, ack_ac_table = tables
    _, trigger_struct = process_table(trigger_struct_table, '10.4', :msg_struct_code => 'SIU_S12')
    _, ack_struct     = process_table(ack_struct_table, '10.4', :msg_struct_code => 'ACK')
    section = '10.4'
    event_codes  = (12..27).reject { |x| x == 25 }.map { |x| 'S' + x.to_s.rjust(2, '0') }
    events = []
    event_codes.each_with_index do |ec, i|
      event = V2AD::Event.new(ec, nil, '10.4.' + (i + 1).to_s)
      events << event
      trigger_msg = event.message
    
      trigger_msg.message_type = find_or_create_message_type('SIU', section)
    
      trigger_msg.message_structure = trigger_struct
    
      ack_message                   = create_ack_message(trigger_msg)
      ack_message.message_type      = find_or_create_message_type('ACK', section)
      ack_message.message_structure = ack_struct
    
      tact = trigger_ac_table.dup.map { |l| l.gsub('S12-S24,S26,S27', ec)}
      _, trig_ac = process_table(tact, '10.4', :msg_struct_code => 'SIU_S12')
      aact = ack_ac_table.dup.map { |l| l.gsub('S12-S24,S26,S27', ec)}
      _, ack_ac = process_table(aact, '10.4', :msg_struct_code => 'ACK')
      trigger_msg.ack_chor = trig_ac
      ack_message.ack_chor = ack_ac
    end
  end

  def extract_11_4_1(original_lines, section, opts)
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.shift
    name = 'Request Patient Authorization'
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

      if l =~ /([A-Z0-9]{3})\^(I08-I11)\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        puts Rainbow(l).magenta if verbose
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
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose#: #{table_buffer.first}"
            table_buffer = []
            text_buffer << "\include::message_structure_table_#{key}"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables[key] ||= {}
            tables[key][:ack_chor] = table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose #: #{table_buffer.first}"
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
    # event = V2AD::Event.new(code, name, section)
    # event.adoc_source = lines
    # event.text = Text.new(text_buffer, true)
    counter = 0
    trigger_struct, trigger_ac, resp_struct, resp_ac = nil
    tables.each do |key, tables|
      counter += 1
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      trigger_struct = obj if counter == 1
      resp_struct    = obj if counter == 2
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      trigger_ac = obj if counter == 1
      resp_ac    = obj if counter == 2      
    end
    
    trigger_ac_11_4(trigger_ac)
    resp_ac_11_4(resp_ac)
  end
  
  def trigger_ac_11_4(set = nil)
    if set
      @tac114 = set
    else
      raise unless @tac114
      @tac114
    end
  end

  def resp_ac_11_4(set = nil)
    if set
      @rac114 = set
    else
      raise unless @rac114
      @rac114
    end
  end
  
  def extract_11_4(original_lines, section, opts = {})
    # puts "Extracting #{section}"
    lines = original_lines.dup
    l1 = lines.shift
    code = l1.slice(/(?<=\(Event).+(?=\))/).strip
    pair = l1.sub(/^\s*=+\s*\d+\.\d+.\d+\s*/, '').sub(/(-|–).+$/, '').strip
    name ||= l1.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    # puts Rainbow("#{pair} #{name} #{code}").lime
    event = V2AD::Event.new(code, name, section)
    event.adoc_source = lines
    event.text = Text.new(lines, true)
    trigger_struct  = V2AD.get_msg_struct('RQA_I08', '11.4.1')
    response_struct = V2AD.get_msg_struct('RPA_I08', '11.4.1')
    raise unless trigger_struct && response_struct
    trigger_ac  = trigger_ac_11_4
    response_ac = resp_ac_11_4
      
    trigger_msg = event.message
    trigger_msg.message_type = find_or_create_message_type('RQA', section)
    trigger_msg.message_structure = trigger_struct
    trigger_msg.ack_chor = trigger_ac
    
    response_message = create_response_message(trigger_msg)
    response_message.message_type = find_or_create_message_type('RPA', section)
    response_message.message_structure = response_struct
    response_message.ack_chor = response_ac

    # While this is true, not creating it now because there is no table in the chapter docx
    # ack_msg = create_ack_message(response_message)
    # ack_msg.message_type = find_or_create_message_type('ACK', section)
    # ack_msg.message_structure = V2AD.general_ack_struct
    # ack_msg.ack_chor = V2AD.general_ack_ac
  end
  
  def extract_11_5(original_lines, opts = {})
    section = '11.5'
    ref = V2AD.find_or_create_message_type('REF', section, 'Patient Referral')
    rri = V2AD.find_or_create_message_type('RRI', section, 'Patient Referral Response')
    lines = original_lines.dup
    l1 = lines.shift
    
    tables = []
    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    lines.each_with_index do |l, i|
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # FIXME should we retain the table formatting directive?
        table = true
      else
        if l.strip =~ /(REF)\^(I12-I15)\^(REF_I12)/
          msg_code        = 'REF'
          msg_struct_code = 'REF_I12'
        elsif l.strip =~ /(RRI)\^(I12-I15)\^(RRI_I12)/
          msg_code        = 'RRI'
          msg_struct_code = 'RRI_I12'
        end

        if table
          if l.strip =~ /\|==+/
            table_mark += 1
            if table_mark > 1
              table = false
              table_mark = 0
              tables << table_buffer.dup
              table_buffer = []
            end
            next
          end
          table_buffer << l
        end
      end
    end
    trigger_struct, trigger_ac, response_struct, response_ac = nil
    tables.each_with_index do |tbl, i|
      if i < 2
        ttype, obj = process_table(tbl, '11.5', :msg_struct_code => 'REF_I12')
        if ttype == :message_structure
          trigger_struct = obj
        elsif ttype == :ack_chor
          trigger_ac = obj
        else
        end
      else
        ttype, obj = process_table(tbl, '11.5', :msg_struct_code => 'RRI_I12')
        if ttype == :message_structure
          response_struct = obj
        elsif ttype == :ack_chor
          response_ac = obj
        else
          raise "WTF"
        end
      end
    end
    
    text_buffer.unshift('')
    events = [
      ['I12', 'Patient Referral', '11.5.2'],
      ['I13', 'Modify Patient Referral', '11.5.3'],
      ['I14', 'Cancel Patient Referral', '11.5.4'],
      ['I15', 'Request Patient Referral Status', '11.5.5'],
    ]

    events.each do |ev_array|
      code, name, section = ev_array
      event = V2AD::Event.new(code, name, section)
      lines = File.readlines("#{adoc_dir(11)}/#{section}.adoc")
      event.adoc_source = lines
      event.text = Text.new(lines + text_buffer, true)
      
      trigger_msg = event.message
      trigger_msg.message_type = ref
      trigger_msg.message_structure = trigger_struct
      trigger_msg.ack_chor = trigger_ac
      
      response_message = create_response_message(trigger_msg)
      response_message.message_type = rri
      response_message.message_structure = response_struct
      response_message.ack_chor = response_ac
    end
  end
  
  def extract_11_6_2(original_lines, opts = {})
    section = '11.6.2'
    ccr = V2AD.find_or_create_message_type('CCR', section,'Collaborative Care Referral')
    lines = original_lines.dup
    l1 = lines.shift
    
    tables = []
    text_buffer  = []
    table_buffer = []
    table = false
    table_mark = 0
    lines.shift if lines.first.strip == ''
    lines.each_with_index do |l, i|
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # FIXME should we retain the table formatting directive?
        table = true
      else
        if l.strip =~ /(CCR)\^(I16-I18)\^(CCR_I16)/
          msg_code        = 'CCR'
          msg_struct_code = 'CCR_I16'
        end

        if table
          if l.strip =~ /\|==+/
            table_mark += 1
            if table_mark > 1
              table = false
              table_mark = 0
              tables << table_buffer.dup
              table_buffer = []
            end
            next
          end
          table_buffer << l
        end
      end
    end
    trigger_struct, trigger_ac = nil
    ack_struct = V2AD.general_ack_struct
    ack_ac     = V2AD.general_ack_ac
    raise "Crap" unless ack_struct && ack_ac
    tables.each_with_index do |tbl, i|
      if i < 2
        ttype, obj = process_table(tbl, '11.6.2', :msg_struct_code => 'CCR_I16')
        if ttype == :message_structure
          trigger_struct = obj
        elsif ttype == :ack_chor
          trigger_ac = obj
        else
        end
      else
        raise "WTF"
      end
    end
    
    text_buffer.unshift('')
    events = [
      ['I16', 'Collaborative Care Referral', '11.6.3'],
      ['I17', 'Modify Collaborative Care Referral', '11.6.4'],
      ['I18', 'Cancel Collaborative Care Referral', '11.6.5']
    ]

    events.each do |ev_array|
      code, name, section = ev_array
      event = V2AD::Event.new(code, name, section)
      lines = File.readlines("#{adoc_dir(11)}/#{section}.adoc")
      event.adoc_source = lines
      event.text = Text.new(lines + text_buffer, true)
      
      trigger_msg = event.message
      trigger_msg.message_type = ccr
      trigger_msg.message_structure = trigger_struct
      trigger_msg.ack_chor = trigger_ac
      
      ack_message = create_ack_message(trigger_msg)
      ack_message.message_type = find_or_create_message_type('ACK', section, 'General Acknowledgment')
      ack_message.message_structure = ack_struct
      ack_message.ack_chor = ack_ac
    end
  end
  
  def extract_8_tables(original_lines, section, opts = {})
    verbose = opts[:verbose]
    lines = original_lines.dup
    # puts lines; puts; puts; puts
    l1 = lines.shift
    pair = l1.sub(/^\s*=+\s*\d+\.\d+.\d+\s*/, '').sub(/(-|–).+$/, '').strip
    name = opts[:name]
    # puts Rainbow(name).lime if name
    name ||= l1.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    name ||= l1.slice(/Order Status Update (?=\(Event O51)/)&.strip
    puts Rainbow("#{section} Event #{code}").cyan if verbose
    puts Rainbow("ALERT!").orange + " No name in first line of event section: #{l1}" unless name
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
      puts l.chomp if verbose
      if l =~ /\[width="\d+%",cols=/ # a table is next
        # should we retain the table formatting directive? no....
        table = true
        next
      end
      code = 'M06 or M07'
      if l =~ /([A-Z0-9]{3})\^(M06|M07)\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        puts Rainbow(l.chomp).magenta if verbose
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
      else
        puts Rainbow(l).yellow if l.strip.[](0) && verbose
      end
      # puts Rainbow(msg_code.to_s + '^' + event_code.to_s + '^' + msg_struct_code.to_s).yellow if verbose
    
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
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose#: #{table_buffer.first}"
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
    eventM06 = V2AD::Event.new('M06', 'Clinical Trials Master File Message', section, lines)
    eventM07 = V2AD::Event.new('M07', 'Clinical Trials Master File Message', section, lines)
    txt = Text.new(text_buffer, true)
    eventM06.text = txt
    eventM06.text = txt
    if tables.size != 4
      # pp tables
      puts Rainbow("#{tables.size} Weird Event Tables in section #{section}!").red
      raise tables.keys.inspect
    end
    counter = 0
    m06_struct, m07_struct, m06_resp_struct, m07_resp_struct = nil
    m06_ac, m07_ac, m06_resp_ac, m07_resp_ac = nil
    tables.each do |key, tables|
      counter += 1
      # puts key
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      m06_struct      = obj if counter == 1
      m06_resp_struct = obj if counter == 2
      m07_struct      = obj if counter == 3
      m07_resp_struct = obj if counter == 4
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      m06_ac      = obj if counter == 1
      m06_resp_ac = obj if counter == 2
      m07_ac      = obj if counter == 3
      m07_resp_ac = obj if counter == 4
    end

    message_type          = find_or_create_message_type('MFN', section)
    response_message_type = find_or_create_message_type('MFK', section)
    ack_type              = find_or_create_message_type('ACK', section)
    
    m06_message = eventM06.message
    m06_message.message_type = message_type
    m06_message.message_structure = m06_struct
    m06_message.ack_chor = m06_ac
    
    m07_message = eventM07.message
    m07_message.message_type = message_type
    m07_message.message_structure = m07_struct
    m07_message.ack_chor = m07_ac
  
    m06_resp_message = V2AD::Message.new
    m06_resp_message.message_type = response_message_type
    m06_resp_message.message_structure = m06_resp_struct
    m06_resp_message.ack_chor = m06_resp_ac
  
    m07_resp_message = V2AD::Message.new
    m07_resp_message.message_type = response_message_type
    m07_resp_message.message_structure = m07_resp_struct
    m07_resp_message.ack_chor = m07_resp_ac
    
    m06_ack_message = V2AD::Message.new
    m06_ack_message.message_type = ack_type
    m06_ack_message.message_structure = V2AD.general_ack_struct
    m06_ack_message.ack_chor = V2AD.general_ack_ac
    
    m07_ack_message = V2AD::Message.new
    m07_ack_message.message_type = ack_type
    m07_ack_message.message_structure = V2AD.general_ack_struct
    m07_ack_message.ack_chor = V2AD.general_ack_ac
    
    m06_message.add_response(m06_resp_message)
    m07_message.add_response(m07_resp_message)
    
    m06_resp_message.ack = m06_ack_message
    m07_resp_message.ack = m07_ack_message
  end
  
  def extract_16_3_4(original_lines, section, opts = {})
    code = 'E03'
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.shift
    name = 'HealthCare Services Invoice Status Query Response'
    puts Rainbow("#{section} Event #{code}").cyan if verbose

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

      if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
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
    event = V2AD.v2.events['E03'].find { |e| e.section == '16.3.3' }
    raise "Drat" unless tables.size == 1
    counter = 0
    resp_struct, resp_ac = nil
    tables.each do |key, tables|
      counter += 1
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      resp_struct = obj if counter == 1
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      resp_ac = obj if counter == 1
    end
    
    trigger_message = event.message
    
    resp_msg = create_response_message(trigger_message)
    resp_msg.text = Text.new(text_buffer, true)
    resp_msg.section = section
    resp_msg.adoc_source = lines
    resp_msg.message_type = find_or_create_message_type('RSP', section)
    resp_msg.message_structure = resp_struct
    resp_msg.ack_chor          = resp_ac
    
    ack_msg = create_ack_message(resp_msg)
    ack_msg.message_type = find_or_create_message_type('ACK', section)
    ack_msg.message_structure = V2AD.general_ack_struct
    ack_msg.ack_chor = V2AD.general_ack_ac
  end

  def extract_16_3_13(original_lines, section, opts = {})
    code = 'E22'
    verbose = opts[:verbose]
    lines = original_lines.dup
    l1 = lines.shift
    name = 'HealthCare Services Invoice Status Query Response'
    puts Rainbow("#{section} Event #{code}").cyan if verbose

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

      if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        # puts Rainbow(l).magenta
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
    event = V2AD.v2.events['E22'].find { |e| e.section == '16.3.12' }
    raise "Drat" unless tables.size == 1
    counter = 0
    resp_struct, resp_ac = nil
    tables.each do |key, tables|
      counter += 1
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      resp_struct = obj if counter == 1
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      resp_ac = obj if counter == 1
    end
    
    trigger_message = event.message
    
    resp_msg = create_response_message(trigger_message)
    resp_msg.text = Text.new(text_buffer, true)
    resp_msg.section = section
    resp_msg.adoc_source = lines
    resp_msg.message_type = find_or_create_message_type('RSP', section)
    resp_msg.message_structure = resp_struct
    resp_msg.ack_chor          = resp_ac
    
    ack_msg = create_ack_message(resp_msg)
    ack_msg.message_type = find_or_create_message_type('ACK', section)
    ack_msg.message_structure = V2AD.general_ack_struct
    ack_msg.ack_chor = V2AD.general_ack_ac
  end
  
  def extract_17_6_x(original_lines, section, opts = {})
    verbose = opts[:verbose] #|| true
    puts Rainbow("Extracting #{section}").plum if verbose
    lines = original_lines.dup
    l1 = lines.shift
    name ||= l1.slice(/(?<=(-|–)).+(?=\([E|e]vent)/)&.strip

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

      if l =~ /([A-Z0-9]{3})\^([A-Z0-9]{3})\^([A-Z0-9]{3}_[A-Z0-9]{3}):/
        # puts Rainbow(l).lawngreen
        # if l =~ /([A-Z0-9]{3})\^(#{code})\^([A-Z0-9]{3}_[A-Z0-9]{3}):\s+(.*)\s*(Message|Description)?/
        msg_code        = $1
        event_code      = $2
        msg_struct_code = $3
      elsif l.strip =~ /ACK\^(#{event_code})\^ACK:/
        # puts Rainbow(l).lawngreen
        msg_code        = 'ACK'
        # event_code      = $1
        msg_struct_code = 'ACK'
      else
        # puts Rainbow(l).yellow
      end
      
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
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose#: #{table_buffer.first}"
            table_buffer = []
            text_buffer << "\include::message_structure_table_#{key}"
            next
          end
          if table_buffer.first =~ ack_chor_table_regex
            ttype = Rainbow("ACK_CHOR  " ).gold
            tables[key] ||= {}
            tables[key][:ack_chor] = table_buffer.dup
            puts "#{ttype} -- #{msg_code}^#{event_code}^#{msg_struct_code}" if verbose #: #{table_buffer.first}"
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
    event = V2AD::Event.new(event_code, name, section)
    event.adoc_source = lines
    event.text = Text.new(text_buffer, true)
    counter = 0
    trigger_struct, trigger_ac, ack_struct, ack_ac, resp_struct, resp_ac = nil
    # pp tables
    tables.each do |key, tables|
      counter += 1
      ms = key.split('^').last
      ms_table       = tables[:message_structure]
      ack_chor_table = tables[:ack_chor]
      _, obj = process_table(ms_table, section, :msg_struct_code => ms)
      trigger_struct = obj if counter == 1
      ack_struct = obj if counter == 2
      resp_struct = obj if counter == 3
      _, obj = process_table(ack_chor_table, section, :msg_struct_code => ms)
      trigger_ac = obj if counter == 1
      ack_ac     = obj if counter == 2      
      resp_ac    = obj if counter == 3      
    end
    
    case section
    when '17.6.1', '17.6.2'
      tmt = 'SLR'
      rmt = 'SLS'
    when '17.6.3'
      tmt = 'STI'
      rmt = 'STS'
    when '17.6.4'
      tmt = 'SDR'
      rmt = 'SDS'
    when '17.6.5'
      tmt = 'SMD'
      rmt = 'SMS'
    else
      raise 'Oh crap'
    end
    
    trigger_message = event.message
    trigger_message.message_type = find_or_create_message_type(tmt, section)
    trigger_message.message_structure = trigger_struct
    trigger_message.ack_chor = trigger_ac
    
    ack_msg = create_ack_message(trigger_message)
    ack_msg.message_type = find_or_create_message_type('ACK', section)
    ack_msg.message_structure = ack_struct
    ack_msg.ack_chor          = ack_ac
    
    resp_msg = create_response_message(trigger_message)
    resp_msg.message_type = find_or_create_message_type(rmt, section)
    resp_msg.message_structure = trigger_struct # ! same as resp_struct
    resp_msg.ack_chor          = resp_ac    
    
    resp_msg.ack = ack_msg
  end
end  
