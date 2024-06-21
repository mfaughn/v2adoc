module V2AD
  module_function
  
  def extract_11_5_1(section, opts)
    opts[:response] = true
    extract_dislocated_struct(section, :@ref_i12, :@ref_i12_ac, :@rri_i12, :@rri_i12_ac, opts)    
  end
  
  def extract_11_5(section, opts = {})
    connect_dislocated_struct(section, 'REF', @ref_i12, @ref_i12_ac, 'RRI', @rri_i12, @rri_i12_ac, opts)
    return
    
    # section_num = section.num
    # ttl = section.title
    # code = ttl.slice(/(?<=\(Event).+(?=\))/).strip
    # name ||= ttl.slice(/(?<=(-|–)).+(?=\(Event)/)&.strip
    # raise unless code && name
    #
    # event = V2AD::Event.new(code, name, section)
    #
    # trigger_struct  = V2AD.get_msg_struct('REF_I12', '11.5.1')
    # response_struct = V2AD.get_msg_struct('RRI_I12', '11.5.1')
    # raise unless trigger_struct && response_struct
    #
    # trigger_ac  = trigger_ac_11_5
    # response_ac = resp_ac_11_5
    #
    # trig_msg                   = event.message
    # trig_msg.message_type      = find_or_create_message_type('REF', section)
    # trig_msg.message_structure = trigger_struct
    # trig_msg.ack_chor          = trigger_ac
    #
    # resp_msg                   = create_response_message(trig_msg)
    # resp_msg.message_type      = find_or_create_message_type('RRI', section)
    # resp_msg.message_structure = response_struct
    # resp_msg.ack_chor          = response_ac

    # While this is true, not creating it now because there is no table in the chapter docx
    # ack_msg = create_ack_message(resp_msg, true)
  end
  
  # def trigger_ac_11_5(set = nil)
  #   if set
  #     @tac115 = set
  #   else
  #     raise unless @tac115
  #     @tac115
  #   end
  # end
  #
  # def resp_ac_11_5(set = nil)
  #   if set
  #     @rac115 = set
  #   else
  #     raise unless @rac115
  #     @rac115
  #   end
  # end
  
  #
  # def extract_11_5(section, opts = {})
  #   section_num = section.num
  #   ref = V2AD.find_or_create_message_type('REF', section, 'Patient Referral')
  #   rri = V2AD.find_or_create_message_type('RRI', section, 'Patient Referral Response')
  #
  #   # events = [
  #   #   ['I12', 'Patient Referral', '11.5.2'],
  #   #   ['I13', 'Modify Patient Referral', '11.5.3'],
  #   #   ['I14', 'Cancel Patient Referral', '11.5.4'],
  #   #   ['I15', 'Request Patient Referral Status', '11.5.5'],
  #   # ]
  #
  #   events.each do |ev_array|
  #     code, name, section_num = ev_array
  #     event = V2AD::Event.new(code, name, section)
  #     lines = File.readlines("#{adoc_dir(11)}/#{section.num}.adoc")
  #
  #     trigger_msg = event.message
  #     trigger_msg.message_type = ref
  #     trigger_msg.message_structure = trigger_struct
  #     trigger_msg.ack_chor = trigger_ac
  #
  #     response_message = create_response_message(trigger_msg)
  #     response_message.message_type = rri
  #     response_message.message_structure = response_struct
  #     response_message.ack_chor = response_ac
  #   end
  # end
  #
  
end
