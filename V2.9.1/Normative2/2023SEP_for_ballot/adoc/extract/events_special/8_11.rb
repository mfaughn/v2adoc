module V2AD
  module_function
  
  
  def extract_8_11(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]
    l1 = section.title
    pair = l1.sub(/(-|–).+$/, '').strip
    name = opts[:name]
    section.display if verbose
    # puts Rainbow(name).lime if name
    name ||= l1.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    puts Rainbow("#{section.num} Event #{code}").cyan if verbose
    puts Rainbow("ALERT!").orange + " No name in first line of event section: #{l1}" unless name

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }

    eventM06 = V2AD::Event.new('M06', 'Clinical Trials Master File Message', section)
    eventM07 = V2AD::Event.new('M07', 'Clinical Trials Master File Message', section)

    if tables.size != 8
      tables.each(&:display)
      puts Rainbow("#{tables.size} Weird Event Tables in section #{section.num}!").red
      raise
    end
    
    m06_struct      = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'MFN_M06')
    m06_ac          = process_ack_chor_table(tables.shift, section)
    m06_resp_struct = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'MFK_M01')
    m06_resp_ac     = process_ack_chor_table(tables.shift, section)
    m07_struct      = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'MFN_M07')
    m07_ac          = process_ack_chor_table(tables.shift, section)
    m07_resp_struct = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'MFK_M01')
    m07_resp_ac     = process_ack_chor_table(tables.shift, section)

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
  
    m06_resp_message = create_response_message(m06_message)
    m06_resp_message.message_type = response_message_type
    m06_resp_message.message_structure = m06_resp_struct
    m06_resp_message.ack_chor = m06_resp_ac
  
    m07_resp_message = create_response_message(m07_message)
    m07_resp_message.message_type = response_message_type
    m07_resp_message.message_structure = m07_resp_struct
    m07_resp_message.ack_chor = m07_resp_ac
    
    # m06_message.add_response(m06_resp_message)
    # m07_message.add_response(m07_resp_message)
    
    m06_ack_message = create_ack_message(m06_resp_message, true)
    m07_ack_message = create_ack_message(m07_resp_message, true)
    
    # puts (m06_ack_message.ack_to.size.to_s)
    # puts (m06_ack_message.ack_to.first == m06_resp_message).to_s
    # puts (m06_resp_message.response_to.first == m06_message).to_s
    # puts m06_message.trigger.code
    # raise
  end

end
