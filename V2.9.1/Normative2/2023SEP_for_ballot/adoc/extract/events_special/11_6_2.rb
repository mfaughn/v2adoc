module V2AD
  module_function
  
  
  def extract_11_6_2(section, opts = {})
    extract_dislocated_struct(section, :@ccr_i16, :@ccr_i16_ac, nil, nil, opts)
    #
    # section_num = section.num
    #
    # tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    #
    # trig_msg_type, trigger_struct, trigger_ac, respack_msg_type, respack_struct, respack_ac, event_codes = process_event_section_tables(section, verbose:opts[:verbose], tables:tables)
    #
    # @ccr_i16    = trigger_struct
    # @ccr_i16_ac = trigger_ac
  end
  
  def extract_11_6(section, opts = {})
    connect_dislocated_struct(section, 'CCR', @ccr_i16, @ccr_i16_ac, nil, nil, nil, opts)
    
    # section_num = section.num
    # # puts "Extracting #{section.num}"
    # ttl = section.title
    # code = ttl.slice(/(?<=\(Event).+(?=\))/).strip
    # name ||= ttl.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    # raise unless code && name
    #
    # event = V2AD::Event.new(code, name, section)
    #
    # trigger_struct  = @ccr_i16
    # raise if trigger_struct.nil?
    #
    # trigger_ac  = @ccr_i16_ac
    # raise if trigger_ac.nil?
    #
    # trig_msg                   = event.message
    # trig_msg.message_type      = find_or_create_message_type('CCR', section)
    # trig_msg.message_structure = trigger_struct
    # trig_msg.ack_chor          = trigger_ac

    # While this is true, not creating it now because there is no table in the chapter docx
    # ack_msg = create_ack_message(resp_msg, true)
  end

end
