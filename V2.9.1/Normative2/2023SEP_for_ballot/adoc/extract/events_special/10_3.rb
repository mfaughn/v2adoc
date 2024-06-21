module V2AD
  module_function

  def extract_10_3(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    
    trigger_struct_table, trigger_ac_table, resp_struct_table, resp_ac_table = tables
    trigger_struct  = process_msg_structure_table(trigger_struct_table, section, :msg_struct_code => 'SRM_S01')
    response_struct = process_msg_structure_table(resp_struct_table,    section, :msg_struct_code => 'SRR_S01')

    event_codes  = (1..11).map { |x| 'S' + x.to_s.rjust(2, '0') }

    event_codes.each_with_index do |ec, i|
      sec = "#{section.num}.#{i+1}"
      subsection = V2AD.v2.sections[sec][:obj]
      event = V2AD::Event.new(ec, nil, subsection)
      puts "Created event #{event.code} for section #{sec}" if verbose
      
      trig_msg = event.message
      trig_msg.message_type = find_or_create_message_type('SRM', section)
      trig_msg.message_structure = trigger_struct
      
      resp_msg                   = create_response_message(trig_msg)
      resp_msg.message_type      = find_or_create_message_type('SRR', section)
      resp_msg.message_structure = response_struct
            
      tact = Table.new
      tact.rows = trigger_ac_table.rows.map { |r| r.gsub('S01-S11', ec) }
      trig_ac = process_ack_chor_table(tact, section)
      
      ract = Table.new
      ract.rows = resp_ac_table.rows.map { |r| r.gsub('S10-S11', ec)} # note that S10-S11 is what is in the text but is wrong and should've been S01-S11
      resp_ac = process_ack_chor_table(ract, section)

      trig_msg.ack_chor = trig_ac
      resp_msg.ack_chor = resp_ac
    end
  end
  
end
