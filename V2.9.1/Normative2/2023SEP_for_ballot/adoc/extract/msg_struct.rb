module V2AD
  module_function
  
  def process_msg_structure_table(table, section, opts = {})
    verbose = opts[:verbose]
    # verbose = true if section.num =~ /16./
    code = opts[:msg_struct_code]
    unless code
      codes = table.get_message_codes_from_caption
      raise "abnormal codes from #{table.caption || table.possible_caption} -- #{codes.inspect}" unless codes.size == 3
      code = codes[2]
    end
    section.display(coler: :lime) if verbose
    # puts lines unless opts[:msg_struct_code]
    msg_structure = get_msg_struct(code, section.num)
    if msg_structure
      puts Rainbow("Using existing MessageStructure for ").cyan + "#{code}" if verbose
      table.objects << msg_structure
      return msg_structure
    end
    if code == 'QBP_Q21' && section == '15.3.7'
      msg_structure = V2AD.get_msg_struct(code, '3.3.58')
      if msg_structure
        puts Rainbow("Using existing MessageStructure for ").cyan + "#{code} " if verbose
        table.objects << msg_structure
        return msg_structure
      else
        raise "Darn"
      end
    end
    msg_structure = V2AD::MessageStructure.new(code, section)
    puts Rainbow("Struct ").green + code if verbose
  # puts Rainbow(section + " #{msg_structure.code}").green
  # puts lines[0..4]
    V2AD.add_msg_struct(msg_structure, section)

    current_container = msg_structure
    # puts table.rows
    table.rows[1..-2].each_with_index do |original_row, i|
      next if i == 0 # it is the header row
      l = original_row.dup
      l = l[1..-1] if l[0] == '|'
      # puts l
      row = remove_empty_cells(l).split(/(?<!\\)\|/)
      # puts "A: #{row}"
      row = row.map(&:strip)
      row = [row[0], row[1], '', row[2]] if row.size == 3
      if row.size < 3 && row[1] !~ /begin|end/
        if row.size == 2
          if row[1] =~ /^\d+$/
            row = [row[0], 'DESCRIPTION NEEDED', 'A', row[1]]
          else
            row = [row[0], row[1], 'A', 'Nobody Cares...']
          end
        end
        if row.size == 1
          if row[0].empty?
          elsif row[0] =~ /^[\\\{\}\|\[\]]+$/
          elsif row[0] =~ /[A-Z]{3}|\.\.\./
            # puts Rainbow(row.inspect).orange + " #{section.num}"
            row = [row[0], 'DESCRIPTION NEEDED', 'A', 'Nobody Cares...']
          else
            puts Rainbow(row.inspect).red + " #{section.num}"
            raise "Don't know what to do with this message structure row."
          end
        end
      end
      # puts "B: #{row}"
      # row = row.map { |c| c.gsub(/\\(?!|)/, '').chomp }
      row = row.map { |c| c.gsub(/\\/, '').chomp }
      # puts "C: #{row}"
      if row.select { |x| x.to_s[0] }.size < 1 && row.uniq != [""]
        puts Rainbow("Empty Segment Row in ").red + Rainbow(section).orange + ': ' + row.inspect
      end
      pp row if verbose
      seg, desc, status, chapter = row
      puts Rainbow(seg).yellow if verbose
      seg, footnote = extract_footnote_from_seg(seg)
      seg     = clean_msg_structure_cell(seg)
      desc    = clean_msg_structure_cell(desc)
      status  = clean_msg_structure_cell(status)
      status = 'A' if status&.empty?
      # chapter = clean_msg_structure_cell(chapter)
      seg = seg.gsub(/\s/, '').gsub('{[', '{').gsub(']}', '}').gsub('[[', '[').gsub(']]', ']')
      # puts Rainbow(seg).gold
      repeating = seg[0..1] =~ /\{/ ? true : false
      optional  = seg[0..1] =~ /\[/ ? true : false
      in_choice = current_container.container.is_a?(V2AD::SegmentChoice) if current_container.respond_to?(:container)

      if seg =~ /([A-Z][A-Z][A-Z0-9])/ || seg =~ /(\.\.\.)/ || seg =~ /(Hxx)/
        code = $1
        raise "No code of #{seg}" unless code
        segment = V2AD::Segment.new(desc)
        if footnote
          # puts Rainbow(footnote).blue
          segment.footnote = footnote
        end
        segment.type     = code # later we replace by processing all segments using V2AD.get_segment_def(code)
        segment.optional = optional
        segment.repeat   = repeating
        segment.status   = status if status
        segment.container = current_container
        current_container.segments << segment
        # puts "#{code}#{optional ? ' optional' : nil} #{repeating ? ' repeat' : nil} #{seg}"
      else
        # Then it is the start or end of a sequence (or choice??)
        if seg =~ /\[|\{/
          # unless desc
          #   table.rows[1..-2].each_with_index do |r, j|
          #     puts (i == j ? Rainbow(r).red : r)
          #   end
          #   section.display
          # end
          desc ||= 'FIXME'  
          # puts "start sequence #{optional ? ' optional' : nil} #{repeating ? ' repeat' : nil} #{seg}"
          seg_seq = V2AD::SegmentSequence.new(desc.strip.sub(/^\s*-*\s*/, '').sub(/\s*(begin|end)$/, ''))
          seg_seq.optional = optional
          seg_seq.repeat   = repeating
          current_container.segments << seg_seq
          seg_seq.container = current_container
          current_container = seg_seq
          puts Rainbow("No opening description in section #{section.num}").orange if desc.strip.empty? && verbose
        elsif seg =~ /\]|\}/
          # puts "end sequence #{seg}"
          current_container = current_container.container
          if desc.to_s.strip.empty?
            puts Rainbow("No closing description for segment group in section #{section.num}").orange if verbose
          end
        elsif seg =~ /</
          seg_choice = V2AD::SegmentChoice.new(desc.strip.sub(/^\s*-*\s*/, '').sub(/\s*(begin|end)$/, ''))
        
          # FIXME -- A choice is a set of sequences where each sequence is of length 1 or more.
          # puts "start sequence #{optional ? ' optional' : nil} #{repeating ? ' repeat' : nil} #{seg}"
          # seg_seq.optional = optional
          # seg_seq.repeat   = repeating
          current_container.segments << seg_choice
          # in_choice = true
          seg_choice.container = current_container
          current_container = seg_choice
          group = V2AD::SegmentGroup.new(seg_choice)
          current_container.groups << group
          group.container = current_container
          current_container = group
        elsif seg =~ />/
          # puts "end choice #{seg}"
          # exit last group and exit choice segment
          # pp current_container.container
          if current_container.container.groups.size < 2
            # unless ['16.3.1', '16.3.2'].include?(section)
            unless section.num =~ /^16\.3\.(1|2|3|4|5|9|10|11|12|13|14)$/ || section.num =~ /^17\.(6|7)\.(4|5)$/
              raise "Section #{section.num} has a message structure with a choice and fewer than two choices"
            end
          end
          current_container = current_container.container.container
        elsif seg == '|'
          unless current_container.is_a?(V2AD::SegmentGroup)
            puts Rainbow("POOP line #{i+1} -- #{row.inspect}").red unless row.uniq == [""]
            raise "Not in a group! Section #{section.num}"
          end
          current_container = current_container.container # so now it is the SegmentChoice
          group = V2AD::SegmentGroup.new(seg_choice)
          current_container.groups << group
          group.container = current_container
          current_container = group
          next
        else
          # puts l
          puts Rainbow("POOP line #{i+1} -- #{row.inspect}").red unless row.uniq == [""]
        end
      end
      if seg.strip =~ /\|$/
        unless current_container.is_a?(V2AD::SegmentGroup)
          puts Rainbow("POOP line #{i+1} -- #{l.inspect}").red + " seg = #{seg.inspect}"
          raise "Not in a group! Section #{section.num}"
        end
        current_container = current_container.container # so now it is the SegmentChoice
        group = V2AD::SegmentGroup.new(seg_choice)
        current_container.groups << group
        group.container = current_container
        current_container = group
      end
    end
    table.objects << msg_structure
    # puts Rainbow('-'*33).orange
    msg_structure
  end
  
  def extract_footnote_from_seg(seg)
    return [seg, nil] unless seg =~ /footnote:/
    fn = seg.slice(/footnote:\[.+\]/)
    [seg.sub(fn, ''), fn.sub('footnote:', '').sub(/^\[/, '').sub(/\]$/, '')]
  end
  
  def clean_msg_structure_cell(str)
    return str unless str =~ /file|link/
    str = remove_underline(str)
    linkless = remove_link_link(remove_file_link(str))
  end
  
end
