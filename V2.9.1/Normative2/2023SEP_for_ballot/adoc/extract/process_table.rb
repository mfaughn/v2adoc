module V2AD
  module_function
  
  def process_table(lines, section, opts = {})
    # puts lines; puts Rainbow('----------------------').orange
    # puts Rainbow(lines.first).cyan
    if is_message_structure_table_header?(lines.first) && section != '2.13.13'
      lines.shift
      [:message_structure, process_msg_structure_table(lines, section, opts)]
    elsif lines.first =~ ack_chor_table_regex
      lines.shift      
      [:ack_chor, process_ack_chor_table(lines, section, opts)]
    elsif is_segment_table_header?(lines.first)
      [:segment_definition, process_segment_table(lines, section, opts)]
    else
      puts Rainbow("#{section} has another kind of table.").magenta + " #{lines.first}"
      [:other, lines]
    end
  end
end
