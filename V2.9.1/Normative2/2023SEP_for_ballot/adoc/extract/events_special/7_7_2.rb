#  This is very similar to 7_7_1 and they could be refactored to be DRY...
module V2AD
  module_function
  def extract_7_7_2(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]
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
      V2AD::Event.new(c, n, section)
    end
    puts Rainbow("#{section.num} Events C09-C12").cyan if verbose

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }

    if tables.size != 5
      tables.each(&:display)
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section.num}!").red
      raise "Fudge..."
    end
    
    trigger_struct = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'CSU_C09')
    ack_chors = event_range.map { |n| process_ack_chor_table(tables.shift, section) }

    crm = find_or_create_message_type('CSU', section, 'Unsolicited Study Data')
    messages = events.map(&:message)
    # ack_type = find_or_create_message_type('ACK', section)
    # ack_messages = event_range.map do
    #   am                   = V2AD::Message.new(section)
    #   am.message_type      = ack_type
    #   am.message_structure = V2AD.general_ack_struct
    #   am.ack_chor          = V2AD.general_ack_ac
    #   am
    # end
    
    messages.each_with_index do |m, i|
      m.message_type      = crm
      m.message_structure = trigger_struct
      m.ack_chor          = ack_chors[i]
      ack                 = create_ack_message(m, true)
      # m.ack               = ack_messages[i]
    end    
  end
  
end
