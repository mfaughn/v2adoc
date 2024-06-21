files = ['v2', 'v2_classes', 'extract', 'process_table',  'datatypes', 'events', 'events_special', 'query_response', 'msg_struct', 'ack_chor', 'segments', 'analyze',  'text_processing', 'regex']
files.each do |f|
  # puts "requiring #{f}.rb"
  load File.expand_path(f + '.rb', __dir__)
end
