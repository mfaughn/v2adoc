module V2AD
  module_function
  
  def process_table(table, section, opts = {})
    # puts table.rows; puts Rainbow('----------------------').orange
    # puts Rainbow(table.caption || table.possible_caption).cyan
    if [:message_structure, :ack_message_structure, :query_message_structure, :response_message_structure].include?(table.type)
      process_msg_structure_table(table, section, opts)
    elsif table.type == :ack_chor
      lines.shift      
      process_ack_chor_table(table, section, opts)
    elsif table.type == :segment_definition
      process_segment_table(table, section, opts)
    else
      puts Rainbow("#{section.num} has another kind of table.").magenta + " #{table.caption || table.possible_caption}"
      table
    end
  end
end
