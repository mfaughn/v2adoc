module V2AD
  module_function

  def section_number_regex
    /^\*?\d+A?(\.\d+)*\*?\s*/
  end
  
  def _regex_test(regex, str = nil)
    if str
      str =~ regex
    else
      regex
    end
  end
  
  def er7_regex(str = nil)
    regex = /^[A-Z][A-Z][A-Z0-9]\|.*\|/
    _regex_test(regex, str)
  end
  
  def is_er7?(str)
    er7_regex(str)
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
    regex = /^Definition: /
    _regex_test(regex, str)
  end
  
  def is_definition?(str)
    definition_regex(str)
  end 
  
  def image_regex(str = nil)
    regex = /^image:/
    _regex_test(regex, str)
  end
  
  def is_image?(str)
    image_regex(str)
  end 
  
  # Message Structure Tables
  def message_structure_table_caption_regex(str = nil)
    regex = /^[A-Z]{3}\^[A-Z]\d\d\^[A-Z]{3}_[A-Z]\d\d:\s+[A-Z]{3}\s+[A-Z]/
    _regex_test(regex, str)
  end
  
  def query_message_structure_table_caption_regex(str = nil)
    regex = /^[A-Z]{3}\^[A-Z]\d\d\^[A-Z]{3}_[A-Z]\d\d:\s+.*Query/
    _regex_test(regex, str)
  end
  
  def response_message_structure_table_caption_regex(str = nil)
    regex = /^[A-Z]{3}\^[A-Z]\d\d\^[A-Z]{3}_[A-Z]\d\d:\s+.*Response/
    _regex_test(regex, str)
  end
  
  def message_structure_table_header_regex(str = nil)
    regex = /\s*\|\s*Segments\s*\|\s*Descriptions?\s*\|\s*Status\s*\|\s*(Chapter|Sec\.? Ref)\s*/
    _regex_test(regex, str)
  end
  
  def is_message_structure_table_header?(str, verbose = false)
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
  
  def ack_message_structure_table_caption_regex(str = nil)
    regex = /^ACK\^[A-Z]\d\d\^ACK:\s+[A-Z].*A[cC][kK]/
    _regex_test(regex, str)
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
