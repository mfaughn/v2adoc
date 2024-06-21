module V2AD
  module_function
    
  def extract_dislocated_struct(section, tstruct, tac, rstruct, rac, opts)
    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }

    trig_msg_type, trigger_struct, trigger_ac, respack_msg_type, respack_struct, respack_ac, event_codes = process_event_section_tables(section, verbose:opts[:verbose], tables:tables)
   
    # @rqa_i08    = trigger_struct
    # @rqa_i08_ac = trigger_ac
    # @rpa_i08    = respack_struct
    # @rpa_i08_ac = respack_ac
    
    V2AD.instance_variable_set(tstruct, trigger_struct)
    V2AD.instance_variable_set(tac, trigger_ac)
    if opts[:response]
      V2AD.instance_variable_set(rstruct, respack_struct)
      V2AD.instance_variable_set(rac, respack_ac)
    end
  end
  
  def connect_dislocated_struct(section, trigger_msg_type_code, trigger_struct, trigger_ac, response_msg_type_code, response_struct, response_ac, opts = {})
    section_num = section.num
    # puts "Extracting #{section.num}"
    ttl = section.title
    code = ttl.slice(/(?<=\(Event).+(?=\))/).strip
    name ||= ttl.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    raise unless code && name

    event = V2AD::Event.new(code, name, section)

    raise section_num if trigger_struct.nil?
    raise section_num if trigger_ac.nil?
  
    trig_msg                   = event.message
    trig_msg.message_type      = find_or_create_message_type(trigger_msg_type_code, section)
    trig_msg.message_structure = trigger_struct
    trig_msg.ack_chor          = trigger_ac

    if response_msg_type_code
      raise section_num if response_struct.nil?
      raise section_num if response_ac.nil?

      resp_msg                   = create_response_message(trig_msg)
      resp_msg.message_type      = find_or_create_message_type(response_msg_type_code, section)
      resp_msg.message_structure = response_struct
      resp_msg.ack_chor          = response_ac
    end
    # While this is true, not creating it now because there is no table in the chapter docx
    # ack_msg = create_ack_message(resp_msg, true)
  end
    
end
