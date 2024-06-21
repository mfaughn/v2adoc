module V2AD
  module_function

  def extract_17_6_x(section, opts = {})
    section_num = section.num
    verbose = opts[:verbose] #|| true
    puts Rainbow("Extracting #{section.num}").plum if verbose

    ttl = section.title
    name = ttl.slice(/(?<=(-|–)).+(?=\([E|e]vent)/)&.strip
    code = ttl.slice(/(?<=\([E|e]vent).+(?=\))/)&.strip
    raise "No name in #{title}" unless name
    raise "No event code in #{title}" unless code

    tables = section.tables.select { |tbl| tbl.type.to_s =~ /message_structure|ack_chor/ }
    
    if tables.size != 6
      tables.each(&:display)
      puts Rainbow("#{tables.size} Weird Event Tables in sectino #{section.num}!").red
      raise "Fudge..."
    end

    event = V2AD::Event.new(code, name, section)

    trigger_struct = process_msg_structure_table(tables.shift, section)
    trigger_ac     = process_ack_chor_table(tables.shift, section)
    ack_struct     = process_msg_structure_table(tables.shift, section)
    ack_ac         = process_ack_chor_table(tables.shift, section)
    resp_struct    = process_msg_structure_table(tables.shift, section)
    resp_ac        = process_ack_chor_table(tables.shift, section)
    
    
    case section.num
    when '17.6.1', '17.6.2'
      tmt = 'SLR'
      rmt = 'SLS'
    when '17.6.3'
      tmt = 'STI'
      rmt = 'STS'
    when '17.6.4'
      tmt = 'SDR'
      rmt = 'SDS'
    when '17.6.5'
      tmt = 'SMD'
      rmt = 'SMS'
    else
      raise 'Oh crap'
    end
    
    trigger_message = event.message
    trigger_message.message_type = find_or_create_message_type(tmt, section)
    trigger_message.message_structure = trigger_struct
    trigger_message.ack_chor = trigger_ac
    
    ack_msg = create_ack_message(trigger_message, true)
    
    resp_msg = create_response_message(trigger_message)
    resp_msg.message_type = find_or_create_message_type(rmt, section)
    resp_msg.message_structure = resp_struct # ! same as trigger_struct
    resp_msg.ack_chor          = resp_ac    
    
    resp_msg.ack = ack_msg
  end
end
