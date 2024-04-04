# Manual fixes necessary
# 4.14.2, 4.14.3, 4.17.2 last field row has values in wrong columns

module V2AD
  module_function

  def extract
    V2AD.v2.reset
    # extract_datatypes
    # extract_ch('2') # Control.  Rob is rewriting it
    # create_variable_segment_def; create_Hxx_segment_def
    # # return
    # extract_ch('1')
    #
    #
    # extract_ch('2A')

    extract_ch('3') # provides general ack struct
    raise
    extract_ch('4')
    extract_ch('4A')
    extract_ch('5')
    extract_ch('6')
    extract_ch('7')
    extract_ch('8')
    extract_ch('9')
    extract_ch('10')
    extract_ch('11')
    extract_ch('12')
    extract_ch('13')
    extract_ch('14')
    extract_ch('15')
    extract_ch('16')
    extract_ch('17')
    link_segment_defintions
  end
  
  def extract_ch(ch)
    verbose = false
    files = Dir["#{adoc_dir(ch)}/*"].sort_by { |f| Gem::Version.new(File.basename(f).sub('.adoc', '').sub('A', '')) }
    # puts files
    files.each do |adoc_file|
      lines   = File.readlines(adoc_file)
      section = File.basename(adoc_file).sub('.adoc', '')
      section_obj = ((ch == '2A') ? V2AD.v2.sections.dig(section, :obj) : V2AD::Section.new(section, lines.dup))
      
      unless section =~ /\.0$/
        raise "No section obj for #{section}" unless section_obj
      end
    end
        
    files.each do |adoc_file|
      opts = {}
      lines = File.readlines(adoc_file)
      section = File.basename(adoc_file).sub('.adoc', '')
      section_obj = v2.sections.dig(section, :obj)
      section_tables = section_obj&.content&.select { |c| c.is_a?(Table) } || []
      # next
      # opts[:verbose] = true if section =~ /^4\.16\.7/
      # puts section if opts[:verbose]
      
      puts Rainbow(section).magenta if opts[:verbose]
      next if section =~ /11\.5\.(2|3|4|5)/
      next if section == '8.4.4'
      
      # unless V2AD.v2.sections.dig(section, :obj)
      #   puts Rainbow("No section_obj for #{section}").orange
      # end
      
      # section_obj = V2AD.v2.sections.dig(section, :obj)
      # if section =~ /\.0$/ && section_obj
      #   puts Rainbow("Zero section_obj for #{section}").orange
      #   pp section_obj.adoc.lines
      # end
      
      # Events
      unless section =~ /^2A?/
        is_event           = false
        has_message_struct = section_tables.find { |table| table.type == :message_structure }

        if found1 = lines.find { |str| str =~ /==+.*\(\s*[E|e]vent/ }
          # puts Rainbow(lines.first).green
          is_event = true
          # puts Rainbow(found1).orange  
        elsif found_response = lines.find { |str| str =~ /==+.*\s*[R|r]esponse\s+\(...\)/ }
          unless section =~ /5\.9\.(1|3|4|5|6)/ || section == '13.3.6.1'
            puts Rainbow("Response Event in #{section}").lime if verbose || opts[:verbose]
            is_event = true
            opts[:response] = true
          end
        elsif lines.any? { |str| str =~ /4\.4\.1(1|3)\.(1|2)\s/ || str =~ /4\.4\.(7|9)\.(1|2)\s/ }
          puts Rainbow(lines.first.chomp).coral + ' SPECIAL' if verbose || opts[:verbose]
          is_event = true
        end

        # if lines.any? { |l| is_message_structure_table_header?(l) }
        #   # puts Rainbow(lines.first).yellow
        #   has_message_struct = true
        # end
      
        if is_event && has_message_struct
          puts Rainbow(section).gold if opts[:verbose]
          extract_events(lines, section, opts)
        end
        # puts Rainbow(section).gold
        if is_event && !has_message_struct
          # FIXME we still need to capture this and create a withdrawn Event
          if lines.find { |l| l =~ /withdrawn|Retained for backwards compatibility/i }
            extract_withdrawn_events(lines, section, opts)
          elsif lines.first =~ /4\.4\.(9|11|13)\s/
            # message structs are in subsections...
          elsif lines.first =~ /10\.3\.\d+\s/
            # puts section
            # puts lines
            extract_event_ch10(lines, section, opts)
          elsif lines.first =~ /10\.4\.\d+\s/
            extract_event_ch10(lines, section)
          else
            if section =~ /11\.4\.(2|3|4|5)/
              extract_11_4(lines, section)
            elsif section =~ /11\.5\.(2|3|4|5)/
              extract_11_5(lines, section, opts)
            elsif section =~ /16\.3\.1(5|6)/
              extract_undefined_event(lines, section, opts)
            else
              puts Rainbow("Alert! No msg struct! #{section.inspect}").red + ' ' + lines.first unless section =~ /11\.6\.(3|4|5)/ || section == '4.4.7' || section =~ /5\.9\.(1|3|4|5|6)/
            end
          
          end
        end
        
        if has_message_struct && !is_event
          if section =~ /5\.3\.\d\.\d/ || section == '5.7.3.1' || section =~ /^5\.9\.\d\.\d\.\d/ || section == '5.9.2.4' || section == '5.9.5.1' || section == '5.9.6.1' || section == '5.9.7.1' || section == '5.9.7.2' || section == '4.6.2' || section == '4A.3.23'
            opts[:query_odd] = true
            extract_events(lines, section, opts)
          else
            puts Rainbow("Section #{section} has message structure with no event.").red unless section == '10.3' || section == '10.4' || section == '11.5.1'
          end
        end
      
        if section == '10.3'
          extract_10_3(lines, opts)
        end
            
        if section == '10.4'
          extract_10_4(lines, opts)
        end
      
        if section == '11.5.1'
          extract_11_5(lines, opts)
        end
      end

      
      
# next
      # Segments
      is_segment  = false
      has_seg_def = false
      if lines.any? { |l| l.strip =~ /==+.*\s*(S|s)egment$/ } || section == '8.8.9' || section == '8.8.15'
        # puts Rainbow(lines.first).green
        is_segment = true
      end
      if lines.any? { |l| is_segment_table_header?(l) }
        # puts Rainbow(lines.first).yellow
        has_seg_def = true
      end
      if is_segment && !has_seg_def
        # FIXME we still need to capture this and create a withdrawn Segment.  I don't even know if there are any of these....
        next if lines.find { |l| l =~ /withdrawn as of/ }
        next if lines.find { |l| l =~ /is described in Chapter/ }
        next if section == '9.2.2.10'
        next if section == '2.9.2.1'
        next if section == '2.9.2.0'
        puts Rainbow("Alert! No seg def! #{section}").red# + ' ' + lines.first
        
        lines.each { |l| puts Rainbow(l).lightskyblue }
      end
      if is_segment && has_seg_def
        extract_segment(lines, section, opts)
      end
      
    end
  end
  
  def report
    puts "DATATYPES #{v2.datatypes.size}"
    # puts
    puts "FIELDS #{v2.fields.size}"
    # pp v2.message_structures
    # puts
    puts "DATA ELEMENTS #{v2.data_elements.size}"
    # pp v2.message_structures
    # puts
    puts "SEGMENT DEFS #{v2.segments.size}"
    # pp v2.segments
    # puts
    puts "EVENTS #{v2.events.size}"
    # pp # V2AD.add_event(event)
    # puts
    puts "MSG STRUCTS #{v2.message_structures.size}"
    # pp v2.message_structures
    # puts
    puts "SECTIONS #{v2.sections.size}"
    # pp v2.sections
    # puts
  end
  
end
