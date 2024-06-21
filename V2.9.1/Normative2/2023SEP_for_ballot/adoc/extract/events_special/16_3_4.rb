module V2AD
  module_function
  def extract_16_3_4(section, opts = {})
    section_num = section.num
    code = 'E03'
    verbose = opts[:verbose]
    name = 'HealthCare Services Invoice Status Query Response'
    puts Rainbow("#{section.num} Event #{code}").cyan if verbose

    event = V2AD.v2.events['E03'].find { |e| e.section.num == '16.3.3' }
    trigger_message = event.message

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    raise "Drat" unless tables.size == 2

    resp_struct = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'RSP_E03')
    resp_ac     = process_ack_chor_table(tables.shift, section)
    
    resp_msg = create_response_message(trigger_message)
    resp_msg.message_type = find_or_create_message_type('RSP', section)
    resp_msg.message_structure = resp_struct
    resp_msg.ack_chor          = resp_ac
        
    # ack_msg = create_ack_message(resp_msg, true)
  end
  
end
