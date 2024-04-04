load File.expand_path('extract/requires.rb', __dir__)

# V2AD.extract_datatypes
V2AD.reset
V2AD.extract
# V2AD.extract_ch('3')
# V2AD.report

# V2AD.analyze_structs;
# V2AD.analyze_data_elements;
# V2AD.analyze_tables;
# V2AD.analyze_acs;
V2AD.analyze_messages;
# V2AD.analyze_seg_seqs;
V2AD.analyze_data_types;

puts Rainbow("********************* Extraction Finished ***********************").cyan
