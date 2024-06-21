module V2AD
  module_function
  def extract_4_4_oddballs(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose]
    if section_num == '4.4.7.1'
      code = 'O22'
      name = "General Laboratory Order Acknowledgment Message - Patient Segments Required"
    elsif section_num == '4.4.7.2'
      code = 'O53'
      name = "General Laboratory Order Acknowledgment Message - Patient Segments Optional"
    elsif section_num == '4.4.9.1'
      code = 'O34'
      name = "Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Required"
    elsif section_num == '4.4.9.2'
      code = 'O54'
      name = "Laboratory order response message to a multiple order related to single specimen OML - Patient Segments Optional"
    elsif section_num == '4.4.11.1'
      code = 'O36'
      name = "Laboratory order response message to a single container of a specimen OML - Patient Segments Required"
    elsif section_num == '4.4.11.2'
      code = 'O55'
      name = "Laboratory order response message to a single container of a specimen OML - Patient Segments Optional"
    elsif section_num == '4.4.13.1'
      code = 'O40'
      name = "Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Required"
    elsif section_num == '4.4.13.2'
      code = 'O56'
      name = "Specimen shipment centric laboratory order response message to specimen shipment OML - Patient Segments Optional"
    else
      raise "WTF?"
    end
    puts Rainbow("#{section.num} Event #{code}").cyan if verbose

    # puts Rainbow(name).orange
    # puts Rainbow(section_num).green
    event_codes     = [] # we need to know if there are multiple events specified in a single section.  If so, we need to handle them and potentially copy the text objects so that they can each be manipulated separately.  TODO: examine an example or three of this
    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }

    if tables.size != 2
      tables.each(&:display)
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section.num}!").red
      raise
    end
    
    trig_msg_type, trigger_struct, trigger_ac, respack_msg_type, respack_struct, respack_ac, event_codes = process_event_section_tables(section, verbose:verbose, tables:tables)
    event = V2AD::Event.new(code, name, section) # do we want to use code or event_code ?? TODO
    
    trig_msg = event.message
    trig_msg.message_type = find_or_create_message_type(trig_msg_type, section)
    trig_msg.message_structure = trigger_struct
    trig_msg.ack_chor = trigger_ac
  
    if respack_msg_type
      raise "See section #{section.num}"
      ack_msg = create_ack_message(trig_msg, true)
    end
  end
   
end
