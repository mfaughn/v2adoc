module V2AD
  module_function
  
  def extract_11_4_1(section, opts)
    opts[:response] = true
    extract_dislocated_struct(section, :@rqa_i08, :@rqa_i08_ac, :@rpa_i08, :@rpa_i08_ac, opts)
  end
  
  def extract_11_4(section, opts = {})
    connect_dislocated_struct(section, 'RQA', @rqa_i08, @rqa_i08_ac, 'RPA', @rpa_i08, @rpa_i08_ac, opts)
    return
    # section_num = section.num
    # # puts "Extracting #{section.num}"
    # ttl = section.title
    # code = ttl.slice(/(?<=\(Event).+(?=\))/).strip
    # name ||= ttl.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    # raise unless code && name
    #
    # event = V2AD::Event.new(code, name, section)
    #
    # trigger_struct  = @rpa_i08
    # raise if trigger_struct.nil?
    #
    # trigger_ac  = @rpa_i08_ac
    # raise if trigger_ac.nil?
    #
    # trig_msg                   = event.message
    # trig_msg.message_type      = find_or_create_message_type('RQA', section)
    # trig_msg.message_structure = trigger_struct
    # trig_msg.ack_chor          = trigger_ac
    #
    # response_struct  = @rpa_i08
    # raise if response_struct.nil?
    #
    # response_ac  = @rpa_i08_ac
    # raise if response_struct.nil?
    #
    # resp_msg                   = create_response_message(trig_msg)
    # resp_msg.message_type      = find_or_create_message_type('RPA', section)
    # resp_msg.message_structure = response_struct
    # resp_msg.ack_chor          = response_ac
    # While this is true, not creating it now because there is no table in the chapter docx
    # ack_msg = create_ack_message(resp_msg, true)
  end
=begin
  def extract_11_4_old(section, opts = {})
    section_num = section.num
    # puts "Extracting #{section.num}"
    ttl = section.title
    code = ttl.slice(/(?<=\(Event).+(?=\))/).strip
    name ||= ttl.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    raise unless code && name
    
    event = V2AD::Event.new(code, name, section)

    trigger_struct  = V2AD.get_msg_struct('RQA_I08', '11.4.1')
    response_struct = V2AD.get_msg_struct('RPA_I08', '11.4.1')
    raise unless trigger_struct && response_struct

    trigger_ac  = trigger_ac_11_4
    response_ac = resp_ac_11_4
      
    trig_msg                   = event.message
    trig_msg.message_type      = find_or_create_message_type('RQA', section)
    trig_msg.message_structure = trigger_struct
    trig_msg.ack_chor          = trigger_ac
    
    resp_msg                   = create_response_message(trig_msg)
    resp_msg.message_type      = find_or_create_message_type('RPA', section)
    resp_msg.message_structure = response_struct
    resp_msg.ack_chor          = response_ac

    # While this is true, not creating it now because there is no table in the chapter docx
    # ack_msg = create_ack_message(resp_msg, true)
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
=end
end
