require 'json'
require 'singleton'

module V2AD
  module_function
  
  def ack_type
    find_or_create_message_type('ACK', section)
  end
  
  def create_ack_message(to_msg, complete = nil)
    # to_msg is the message that this ack is for
    raise "to_msg is nil" unless to_msg
    
    # if to_msg.section.num == '3.3.56'
    #   puts caller
    #   puts Rainbow("Gotcha!").red
    # end
    if to_msg.section.num.nil?
      puts "I refuse to create an ACK message for a message with no section!"
    end
    unless to_msg.trigger || to_msg.response_to.any?
      raise "to_msg is not associated with a trigger event and is not a response to a message"
    end
    
    ack_msg = V2AD::Message.new(to_msg.section)
    ack_msg.message_type = find_or_create_message_type('ACK', 'General ACK')
    if complete
      ack_msg.message_structure = general_ack_struct
      ack_msg.ack_chor          = general_ack_ac
    end
    # puts Rainbow(to_msg).orange
    to_msg.ack = ack_msg
    # puts Rainbow("Created Ack msg #{ack_msg.object_id} as an ack to #{to_msg.code}").lime
    #
    # puts "All ack_to: #{ack_msg.ack_to.map {|x| x.section.num}}"
    ack_msg
  end
  
  def create_response_message(to_msg)
    # to_msg is the message that this response is for
    resp_msg = V2AD::Message.new(to_msg.section)
    to_msg.add_response(resp_msg)
    resp_msg
  end
  
  def reset_general_ack
    @general_ack_struct = nil
    @general_ack_ac     = nil
  end
  
  def general_ack_struct(msg_struct = nil)
    if msg_struct
      puts Rainbow("Setting ACK struct").gold # #{msg_struct.object_id}").gold
      # recorded_ack_structs = V2AD.v2.message_structures['ACK']&.values
      # recorded_ack_structs.each { |ras| puts "#{ras.class} #{ras.object_id}"}
      # puts "general_ack_struct is recorded? #{!!V2AD.v2.message_structures['ACK'].values.find { |ms| ms.object_id == msg_struct.object_id }}"
    end
    @general_ack_struct ||= msg_struct
  end
  
  def general_ack_ac(ac = nil)
    @general_ack_ac ||= ac
  end
  
end
