files = ['extract', 'process_table','v2','datatypes','events','events_special','query_response','msg_struct','ack_chor','segments','analyze', 'text_processing', 'regex']
files.each do |f|
  # puts "requiring #{f}.rb"
  load File.expand_path(f + '.rb', __dir__)
end
