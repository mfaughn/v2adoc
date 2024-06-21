module V2AD
  module_function
  def extract_7_11_1(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]
    p07code = 'P07'
    p08code = 'P08'    
    p07name = 'Unsolicited initial individual product experience report'
    p08name = 'Unsolicited update individual product experience report'
    puts Rainbow("#{section.num} Event P07, P08").cyan if verbose
    event07 = V2AD::Event.new(p07code, p07name, section)
    event08 = V2AD::Event.new(p08code, p08name, section)
 
    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }

    if tables.size != 3
      tables.each(&:display)
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section.num}!").red
      raise
    end
    
    pex_p07_struct = process_msg_structure_table(tables.shift, section, :msg_struct_code => 'PEX_P07')
    ac_07          = process_ack_chor_table(tables.shift, section)
    ac_08          = process_ack_chor_table(tables.shift, section)

    pex = find_or_create_message_type('PEX', section)
    
    p07_message = event07.message
    p08_message = event08.message
    p07_message.message_type = pex
    p08_message.message_type = pex
    p07_message.message_structure = pex_p07_struct
    p08_message.message_structure = pex_p07_struct
    p07_message.ack_chor = ac_07
    p08_message.ack_chor = ac_08
    
    # ack07_msg = create_ack_message(p07_message, true)
    # ack08_msg = create_ack_message(p08_message, true)
  end
  
end
