module V2AD
  module_function

  def extract_7_7_1(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]
    codes = (1..8).map { |n| 'C' + n.to_s.rjust(2,'0') }
    names = [
      'Register a patient on a clinical trial',
      'Cancel a patient registration on clinical trial (for clerical mistakes since an intended registration should not be canceled)',
      'Correct/update registration information',
      'Patient has gone off a clinical trial',
      'Patient enters phase of clinical trial',
      'Cancel patient entering a phase (clerical mistake)',
      'Correct/update phase information',
      'Patient has gone off phase of clinical trial'
    ]
    codes_and_names = codes.zip(names)
    events = codes_and_names.map do |c,n|
      V2AD::Event.new(c, n, section)
    end
    puts Rainbow("#{section.num} Events C01-C08").cyan if verbose
    
    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    
    if tables.size != 9
      tables.each(&:display)
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section.num}!").red
      raise "Fudge..."
    end
    
    trigger_struct = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'CRM_C01')
    ack_chors = (1..8).map { process_ack_chor_table(tables.shift, section) }

    crm = find_or_create_message_type('CRM', section, 'Clinical Study Registration')
    messages = events.map(&:message)
    # ack_type = find_or_create_message_type('ACK', section)
    # ack_messages = (1..8).map do
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
