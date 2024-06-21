module V2AD
  module_function
  
  def _regex_test(regex, str = nil)
    if str
      str =~ regex
    else
      regex
    end
  end

  def section_number_regex
    /^\*?\d+A?(\.\d+)*\*?\s*/
  end
  
  def er7_regex(str = nil)
    regex = /^[A-Z][A-Z][A-Z0-9]\|.*\|/
    _regex_test(regex, str)
  end
  
  def is_er7?(str)
    er7_regex(str)
  end
  
  def er7_snippet_regex(str = nil)
    regex = /^\|.+\|/
    _regex_test(regex, str)
  end
  
  def er7_field_regex(str = nil)
    regex = /^\^.+\^/
    _regex_test(regex, str)
  end
  
  def is_er7_snippet?(str)
    er7_snippet_regex(str) || er7_field_regex(str)
  end
  
  def note_regex(str = nil)
    regex = /^\*?Note:?/
    _regex_test(regex, str)
  end
  
  def is_note?(str)
    note_regex(str)
  end
  
  def example_regex(str = nil)
    regex = /^\*?Example:?/
    _regex_test(regex, str)
  end
  
  def is_example?(str)
    example_regex(str)
  end
  
  def data_type_component_regex(str = nil)
    regex = /^Components: </
    _regex_test(regex, str)
  end
  
  def is_data_type_component_expression?(str)
    data_type_component_regex(str)
  end 
  
  def data_type_subcomponent_regex(str = nil)
    regex = /^Subcomponents for /
    _regex_test(regex, str)
  end
  
  def is_data_type_subcomponent_expression?(str)
    data_type_subcomponent_regex(str)
  end
  
  def definition_regex(str = nil)
    regex = /^\s*\*?Definition:\*?/
    _regex_test(regex, str)
  end
  
  def is_definition?(str)
    # answer = !!(definition_regex(str))
    # if str =~ /Definition/i
    #   puts Rainbow(str).coral
    #   puts answer.to_s
    # end
    # answer
    definition_regex(str)
  end 
  
  def image_regex(str = nil)
    regex = /^image:/
    _regex_test(regex, str)
  end
  
  def is_image?(str)
    image_regex(str)
  end 
  
  def message_name_snippets
    # The inclusion of "Description" is to handle what is almost certainly an editorial error
    "((Message|Order|Pharmacy|Unsolicited)|Description|(Create|Cancel) (Subscription|Query)|Response|Billing|Financial|Payment|Update|Observation Report|Master File|Notification|Patient|Collaborative Care|Return Referral|Request|Application Management|Invoice|Results|Information Response|Data Request))"
  end
  
  def message_code_regex(str = nil)
    regex = /([A-Z]{3}\^[A-Z]\d\d\^[A-Z]{3}_[A-Z]\d\d)|(MFN\^M\d\d\^MFN_Znn)/
    _regex_test(regex, str)
  end
    
  def message_structure_table_caption_regex(str = nil)
    regex = Regexp.new("^(#{message_code_regex}|#{message_code_regex_multiple_events}):\s+([A-Z]{3}\s+[A-Z]|.*#{message_name_snippets}")
    # regex = /^(#{message_code_regex}|#{message_code_regex_multiple_events}):\s+([A-Z]{3}\s+[A-Z]|.*#{message_name_snippets}/
    _regex_test(regex, str)
  end
    
  def message_code_regex_multiple_events(str = nil)
    regex = /([A-Z]{3}\^([A-Z]\d\d-[A-Z]\d\d|PC[B\d]-PC[D\d]|(S12-)?([PS][A-Z\d][A-Z\d],)+[PS][A-Z\d][A-Z\d])\^[A-Z]{3}_([A-Z]\d\d|PC[BG\d]))|(MFN\^M\d\d\^MFN_Znn)/
    _regex_test(regex, str)
  end
    
  # def message_structure_table_caption_regex_multiple_events(str = nil)
  #   # The inclusion of "Description" is to handle what is almost certainly an editorial error
  #   regex = /^#{message_code_regex_multiple_events}:\s+([A-Z]{3}\s+[A-Z]|.*#{message_name_snippets}/
  #   _regex_test(regex, str)
  # end
  
  def query_message_code_regex(str = nil)
    regex = /(QBP|QVR|Q[A-Z]{2})\^[EQZ](\d\d|nn)\^[A-Z]{3}_[A-Z](\d\d|nn)/
    _regex_test(regex, str)
  end
  
  def query_message_structure_table_caption_regex(str = nil)
    regex = /^#{query_message_code_regex}:\s+.*Query/
    # regex = /^[A-Z]{3}\^([A-Z]\d\d|Znn)\^[A-Z]{3}_([A-Z]\d\d|Qnn):\s+.*Query/
    _regex_test(regex, str)
  end
  
  def response_message_code_regex(str = nil)
    regex = /(RSP|RTB|RDY|R[A-Z]{2})\^[EKZ](\d\d|nn)\^[A-Z]{3}_[A-Z](\d\d|nn)/
    _regex_test(regex, str)
  end
  
  def response_message_structure_table_caption_regex(str = nil)
    regex = /^#{response_message_code_regex}:\s+.*Response/
    # regex = /^[A-Z]{3}\^([A-Z]\d\d|Znn)\^[A-Z]{3}_([A-Z]\d\d|(Z|K)nn):\s+.*Response/
    _regex_test(regex, str)
  end
  
  def ack_message_code_regex(str = nil)
    regex = /ACK\^[A-Z]\d\d\^ACK/
    _regex_test(regex, str)
  end
  
  def ack_message_code_regex_multiple_events(str = nil)
    regex = /ACK\^([A-Z]\d\d-[A-Z]\d\d|PC[B\d]-PC[D\d]|(S12-)?([PS][A-Z\d][A-Z\d],)+[PS][A-Z\d][A-Z\d])\^ACK/
    _regex_test(regex, str)
  end
  
  def ack_message_structure_table_caption_regex(str = nil)
    regex = /^(#{ack_message_code_regex}|#{ack_message_code_regex_multiple_events}):\s+([A-Z].*A[cC][kK]|Observation Message|Acknowledge?ment|Anti-Microbial Device.*Request Response)/
    _regex_test(regex, str)
  end
  
  def message_structure_table_header_regex(str = nil)
    regex = /\s*\|\s*Segments\s*\|\s*Descriptions?\s*\|\s*Status\s*\|\s*(Chapter|Sec\.? Ref)\s*/
    _regex_test(regex, str)
  end
  
  def is_message_structure_table_header?(str, verbose = false)
    raise "Fix this method?"
    x = remove_empty_cells(str) 
    # puts x # FIXME looking at 5.9.2.3 which should not match because ther is no message_structure_table
    ret = x =~ message_structure_table_header_regex
    if ret
      puts Rainbow(str).green if verbose
    else
      puts Rainbow(str).orange if verbose
    end
    ret
  end
  
  # Segment Definition Tables
  def segment_defitiniton_table_caption_regex(str = nil)
    regex = /HL7 Attribute Table/
    _regex_test(regex, str)
  end
  
  def segment_table_header_regex(str = nil)
    regex = /\s*\|\s*SEQ\s*\|\s*LEN\s*\|\s*C.LEN\s*\|\s*DT\s*\|\s*(OPT|R\/O\/?C?)\s*\|\s*R ?P\/ ?#\s*\|\s*TBL ?#\s*\|\s*ITEM ?#\s*\|\s*(ELEMENT NAME|Element Name)\s*/
    _regex_test(regex, str)
  end
  
  def is_segment_table_header?(str)
    str.gsub(/\|\s+(?=\|)/, '') =~ segment_table_header_regex
  end
  
  # Acknowledgment Choreography Tables
  def ack_chor_table_regex(str = nil)
    regex = /\s*\|\s*Acknowledge?ment Choreography\s*\|/
    _regex_test(regex, str)
  end
  
  # Data Type tables
  def datatype_table_header_regex(str = nil)
    regex = /\|\s*SEQ\s*\|\s*LEN\s*\|/
    _regex_test(regex, str)    
  end
  
  def data_type_defitiniton_table_caption_regex(str = nil)
    regex = /HL7 Component Table/
    _regex_test(regex, str)
  end
  
end


# 2@ t3-2xl
# storage 500gig x2
