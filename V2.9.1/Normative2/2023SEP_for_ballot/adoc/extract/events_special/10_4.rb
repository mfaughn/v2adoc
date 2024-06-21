# Nearly the same as 10_3.  Could make DRY...
module V2AD
  module_function

  def extract_10_4(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }

    trigger_struct_table, trigger_ac_table, ack_struct_table, ack_ac_table = tables
    trigger_struct = process_msg_structure_table(trigger_struct_table, section, :msg_struct_code => 'SIU_S12')
    ack_struct     = process_msg_structure_table(ack_struct_table,     section, :msg_struct_code => 'ACK')

    event_codes  = (12..27).reject { |x| x == 25 }.map { |x| 'S' + x.to_s.rjust(2, '0') }
    
    event_codes.each_with_index do |ec, i|
      sec = "#{section.num}.#{i+1}"
      subsection = V2AD.v2.sections[sec][:obj]
      event = V2AD::Event.new(ec, nil, subsection)
      puts "Created event #{event.code} for section #{sec}" if verbose
      
      trig_msg = event.message    
      trig_msg.message_type = find_or_create_message_type('SIU', section)
      trig_msg.message_structure = trigger_struct
    
      ack_msg = create_ack_message(trig_msg)
      ack_msg.message_type = find_or_create_message_type('ACK', section)
      ack_msg.message_structure = ack_struct
    
      tact = Table.new
      tact.rows = trigger_ac_table.rows.map { |r| r.gsub('S12-S24,S26,S27', ec)}
      trig_ac   = process_ack_chor_table(tact, section)
      
      aact = Table.new
      aact.rows = ack_ac_table.rows.map { |r| r.gsub('S12-S24,S26,S27', ec)}
      ack_ac    = process_ack_chor_table(aact, section)

      trig_msg.ack_chor = trig_ac
      ack_msg.ack_chor  = ack_ac
    end
  end
  
end
