module V2AD

  module_function
  
  def extract_query_response(section, codes, opts = {})
    section_num = section.num
    verbose = opts[:verbose]
    raise unless codes.size == 2
    query_code    = codes.shift
    response_code = codes.shift
    raise if codes.any?

    puts Rainbow("Extract query and response events: #{query_code} and #{response_code}").orange if verbose

    if section_num == '5.4.1'
      names_and_message_types = ['Query by Parameter', 'QBP', 'Segment Pattern Response', 'RSP']
    elsif section_num == '5.4.3'
      names_and_message_types = ['Query by Parameter', 'QBP', 'Display Response', 'RDY']
    elsif section_num == '15.3.7'
      names_and_message_types = ['Query by Parameter', 'QBP', 'Segment Pattern Response', 'RSP']      
    else
      names_and_message_types = section.title.dup.slice(/(?<=(-|–)).+(?=\([E|e]vent)/).strip.split(' and ').map do |str|
        name = str.slice(/.*(?=\()/).strip
        mt   = str.slice(/(?<=\()[A-Z]{3}(?=\))/).strip
        [name, mt]
      end
    end
    query_name, query_mt, response_name, response_mt = names_and_message_types.flatten
    response_name        = query_name + response_name if response_name == 'Response'
    query_message_type   = find_or_create_message_type(query_mt, section)
    response_msg_type    = find_or_create_message_type(response_mt, section)
  
    query_event    = V2AD::Event.new(query_code, query_name, section)
    response_event = V2AD::Event.new(response_code, response_name, section)
    
    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    
    query_struct    = process_msg_structure_table(tables.shift, section)
    query_ac        = process_ack_chor_table(tables.shift, section)
    response_struct = process_msg_structure_table(tables.shift, section)
    response_ac     = process_ack_chor_table(tables.shift, section)
      
    query_message = query_event.message
    query_message.message_type = query_message_type
    query_message.message_structure = query_struct
    query_message.ack_chor = query_ac
  
    response_msg = response_event.message
    response_msg.message_type = response_msg_type
    response_msg.message_structure = response_struct
    response_msg.ack_chor          = response_ac
    if response_msg_type.code =~ /ACK/
      puts Rainbow("Response to #{query_message_type.code}^#{query_event.code}^#{query_struct.code} is ACK!").red
      query_message.ack = response_msg
    else
      query_message.add_response(response_msg)
    end
    
    if verbose# || query_message.code =~ /Q21/
      puts "From Section #{section_num}"
      puts "Query message is #{query_message.code}"
      puts "Ack: #{query_message.ack}"
      puts "Response message is #{response_msg.code}"
      puts "Ack: #{response_msg.ack}"
    end
    # raise if query_message.code =~ /Q21/
  end
  
  # FIXME this is more or less just a regular event with no explicit ack table....or is it?
  def extract_response(section, code, opts = {})
    verbose = opts[:verbose]
    response_code = code
    section.display; raise unless section.num == '5.4.2'

    puts Rainbow("Extract response event: #{response_code}").orange if verbose

    response_name = 'Tabular Response'
    response_msg_type = find_or_create_message_type('RTB', section)
  
    response_event = V2AD::Event.new(response_code, response_name, section)

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }

    if tables.size != 2
      tables.each(&:display)
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section.num}!").red
      raise
    end
    
    response_struct = process_msg_structure_table(tables.shift, section)
    response_ac     = process_ack_chor_table(tables.shift, section)
    
    response_msg                   = response_event.message
    response_msg.message_type      = response_msg_type
    response_msg.message_structure = response_struct
    response_msg.ack_chor          = response_ac
        
    # ack_msg = V2AD::Message.new(section)
    # ack_msg.message_type = find_or_create_message_type('ACK', section)
    # ack_msg.message_structure = V2AD.general_ack_struct
    # ack_msg.ack_chor          = V2AD.general_ack_ac
    #
    # response_msg.ack = ack_msg
  end
end
