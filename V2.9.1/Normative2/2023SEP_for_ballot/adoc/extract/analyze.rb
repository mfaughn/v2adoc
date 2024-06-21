require 'diffy'
module V2AD
  
  module_function
  
  # FIXME deal with --> 3.3.8 somehow tranposes the last segment [PDA] to be the first segment
  # Write consolidation code that pushes all identical message structures into a single instance so that we can have fewer combinations.  This is particularly important with ACK.
  def consolidated_structs
    @consolidated_structs ||= {}
  end
  
  
  def consolidate_structs
    ss = v2.message_structures
    # check to see that all shared structures are the same every time they were included in the docx
    multis = ss.select { |k,v| v.size > 1 }
    puts "There are #{multis.size} shared structs"
    multis.each do |code, h1|
      consolidated_structs[code] ||= {}
      version = 'A'
      h1.each  do |section, struct|
        this_json = JSON.pretty_generate(struct.to_hash_all)
        # if analysis[code].empty?
        #   analysis[code][version] = {:sections => [section], :json => json}
        #   next
        # end
        found = false
        consolidated_structs[code].each do |ver, data|
          that_json = JSON.pretty_generate(data[:all])
          if this_json == that_json
            data[:sections] << section
            found = true
          end
        end
        next if found
        consolidated_structs[code][version] = { :sections => [section], :all => struct.to_hash_all, :vals => struct.to_hash_vals }
        version.succ!
      end
    end
    # consolidated_structs.each do |c, versions|
    #   puts Rainbow("#{c} had #{versions.size} versions")
    #   versions.each { |ver, data| puts "#{ver} - #{data[:sections]}" }
    # end
  end    
  
  def analyze_structs
    consolidate_structs
    # return
    struct_diffs_dir = File.expand_path('diff/structs', __dir__)
    FileUtils.rm_rf(struct_diffs_dir)
    struct_diffs_dir_vals = File.expand_path('diff/structs/vals_differ', __dir__)
    struct_diffs_dir_text = File.expand_path('diff/structs/text_differs', __dir__)
    FileUtils.mkdir_p(struct_diffs_dir_vals)
    FileUtils.mkdir_p(struct_diffs_dir_text)
    # raise unless File.exist?(struct_diffs_dir)
    consolidated_structs.each do |code, versions|
      if versions.size == 1
        # puts Rainbow(code).green + ' had 1 version.  Yay!'
        next
      else
        # puts Rainbow(code).yellow + " had #{versions.size} versions.  :-("
      end
      combinations = versions.keys.combination(2)
      combinations.each do |a, b|
        av = versions[a]
        bv = versions[b]
        a_sections = av[:sections]
        a_str_all  = JSON.pretty_generate(av[:all])
        a_str_vals = JSON.pretty_generate(av[:vals])
        b_sections = bv[:sections]
        b_str_all  = JSON.pretty_generate(bv[:all])
        b_str_vals = JSON.pretty_generate(bv[:vals])
        # puts Rainbow("#{code} - #{a_sections} do not match #{b_sections}").orange
        # txt = Diffy::Diff.new(a_str, b_str, :context => 3)#.to_s(:html)
        # puts txt
        div1 = Diffy::Diff.new(a_str_all, b_str_all, :context => 3, :include_plus_and_minus_in_html => true).to_s(:html)
        div2 = Diffy::Diff.new(a_str_all, b_str_all, :include_plus_and_minus_in_html => true).to_s(:html)
        title = "#{a_sections.first}_vs_#{b_sections.first}"
        html_msg = "For #{code} there were #{versions.size} versions found.  This diff compares the version found in sections #{a_sections} with the version found in sections #{b_sections}"

        if a_str_vals == b_str_vals
          code_dir = FileUtils.mkdir_p(File.join(struct_diffs_dir_vals, code))
        else
          code_dir = FileUtils.mkdir_p(File.join(struct_diffs_dir_text, code))
        end
        File.open(File.join(code_dir, "#{title}.html"), 'w+') { |f| f.puts html_diff(div1, div2, title, html_msg) }
      end
    end
  end
    
  def html_diff(div1, div2, title, msg)
    html = []
    html << '<html>'
    html << '<head>'
    html << '<style>'
    html << Diffy::CSS
    html << '</style>'
    html << '</head>'
    html << '<body>'
    html << '<h1>'
    html << title
    html << '</h1>'
    html << '<hr>'
    html << '<h3>'
    html << msg
    html << '</h3>'
    html << '<hr>'
    html << '<h3>'
    html << 'Synopsis Diff'
    html << '</h3>'
    html << '<hr>'
    html << div1
    html << '<hr>'
    html << '</h3>'
    html << '<h3>'
    html << 'Full Message Structure Diff'
    html << '</h3>'
    html << '<hr>'
    html << div2
    html << '</body>'
    html << '</html>'
    html.join("\n")
  end
    
  def old_analyze_structs
    consolidate_structs
    # return
    diffs_dir = File.expand_path('diff/structs', __dir__)
    FileUtils.mkdir_p(diffs_dir)
    raise unless File.exist?(diffs_dir)
    ss = v2.message_structures
    # check to see that all shared structures are the same every time they were included in the docx
    multis = ss.select { |k,v| v.size > 1 }
    puts "There are #{multis.size} shared structs"
    # pp multis.first
    # pp multis.first.json
    # pp multis.first.last.keys#each { |x| puts x.class.name};
    multis.each do |code, h1|
      next unless code == 'ACK'
      jsons = []
      puts Rainbow(code).cyan
      sections = h1.keys
      sections.each do |s|
        jsons << [s, JSON.pretty_generate(h1[s].json)]
      end
      combinations = jsons.combination(2)
      combinations.each do |a,b|
        if a.last == b.last
          # puts Rainbow("#{a.first} matches #{b.first}").green
        else
          puts Rainbow("#{code} - #{a.first} does not match #{b.first}").orange
          txt = Diffy::Diff.new(a.last, b.last, :context => 3)#.to_s(:html)
          puts txt
          div = Diffy::Diff.new(a.last, b.last, :include_plus_and_minus_in_html => true).to_s(:html)
          title = "#{code}_#{a.first}_vs_#{b.first}"
          File.open(File.join(diffs_dir, "#{title}.html"), 'w+') { |f| f.puts html_diff(div, title) }
        end
      end
    end
  end
  
  def register_data_elements
    @data_element_registry = {}
    # puts v2.segment_defs.size
    v2.segment_defs.each do |code, sd|
      ff = sd.fields
      sec = sd.section
      ff.each do |f|
        de = f.data_element
        @data_element_registry[de.item_number] ||= {}
        @data_element_registry[de.item_number]["#{code}-#{f.seq}"] = {:def => de.def_diff_str, :attr => de.attr_diff_str, :all => de.diff_str, :section => sec}
      end
    end
    @data_element_registry
  end
  
  def analyze_data_elements
    registry = register_data_elements
    consolidate_data_elements(registry.select { |k,v| v.size > 1 })
    diffs_dir = File.expand_path('diff/data_elements', __dir__)
    diffs_dir_attr = File.expand_path('diff/data_elements/values_differ', __dir__)
    diffs_dir_defs = File.expand_path('diff/data_elements/definitions_differ', __dir__)
    diffs_dir_both = File.expand_path('diff/data_elements/both_differ', __dir__)
    FileUtils.rm_rf(diffs_dir)
    FileUtils.mkdir_p(diffs_dir_both)
    FileUtils.mkdir_p(diffs_dir_defs)
    FileUtils.mkdir_p(diffs_dir_attr)
    # raise unless File.exist?(diffs_dir)
    consolidated_data_elements.each do |item_number, versions|
      if versions.size == 1
        # puts Rainbow(item_number).green + ' had 1 version.  Yay!'
        next
      else
        # puts Rainbow(item_number).yellow + " had #{versions.size} versions.  :-("
      end
      combinations = versions.keys.combination(2)
      combinations.each do |a, b|
        av = versions[a]
        bv = versions[b]
        a_fields = av[:fields].map(&:first)
        a_str    = av[:diff][:all]
        a_def    = av[:diff][:def]
        a_vals   = av[:diff][:attr]
        b_fields = bv[:fields].map(&:first)
        b_str    = bv[:diff][:all]
        b_def    = bv[:diff][:def]
        b_vals   = bv[:diff][:attr]
        # puts Rainbow("#{item_number} - #{a_fields} do not match #{b_fields}").orange
        
        # txt = Diffy::Diff.new(a_str, b_str, :context => 3)#.to_s(:html)
        # puts txt
        div1 = Diffy::Diff.new(a_str, b_str, :context => 0, :include_plus_and_minus_in_html => true).to_s(:html)
        div2 = Diffy::Diff.new(a_str, b_str, :include_plus_and_minus_in_html => true).to_s(:html)
        title = "#{a_fields.first}_vs_#{b_fields.first}"
        html_msg = "For #{item_number} there were #{versions.size} versions found.<br>This diff compares the version found in fields #{a_fields} from sections #{av[:fields].map(&:last)}, respectively<br>with the version found in fields #{b_fields} from sections #{bv[:fields].map(&:last)}, respectively."
        
        defs_differ = a_def != b_def
        vals_differ = a_vals != b_vals
        
        if defs_differ && vals_differ
          item_number_dir = FileUtils.mkdir_p(File.join(diffs_dir_both, item_number))
        else
          if defs_differ
            item_number_dir = FileUtils.mkdir_p(File.join(diffs_dir_defs, item_number))
          else
            item_number_dir = FileUtils.mkdir_p(File.join(diffs_dir_attr, item_number))
          end
        end
        File.open(File.join(item_number_dir, "#{title}.html"), 'w+') { |f| f.puts html_diff(div1, div2, title, html_msg) }
      end
    end    
  end
  
  def consolidated_data_elements
    @consolidated_data_elements ||= {}
  end
  
  def consolidate_data_elements(registry)
    registry.each do |item_number, h1|
      consolidated_data_elements[item_number] ||= {}
      version = 'A'
      h1.each  do |field_id, diff_strings|
        str = diff_strings[:all]
        # json = JSON.pretty_generate(json).gsub(/","/, "\",\n\"")
        # puts json
        # if analysis[code].empty?
        #   analysis[code][version] = {:sections => [section], :json => json}
        #   next
        # end
        found = false
        consolidated_data_elements[item_number].each do |version, data|
          if str == data[:diff][:all]
            data[:fields] << [field_id, data[:sec]]
            found = true
          end
        end
        next if found
        consolidated_data_elements[item_number][version] = {:fields => [[field_id, diff_strings[:section]]], :diff => diff_strings}
        version.succ!
      end
    end
    # consolidated_structs.each do |c, versions|
    #   puts Rainbow("#{c} had #{versions.size} versions")
    #   versions.each { |ver, data| puts "#{ver} - #{data[:sections]}" }
    # end
  end    
  
  def analyze_tables
    v2.tables.each do |t, sources|
      if t =~ /:/
        puts t
        puts sources
      end
    end
  end
  
  def analyze_acs
    acs  = v2.ack_chors
    msgs = v2.messages.select { |m| m.trigger&.status != 'W' }
    puts "There are #{acs.size} Acknowledgement Choreographies"
    puts "There are #{msgs.size} Messages"
    acless = []
    msgs.each_with_index do |msg, i|
      # print " #{i+1}"
      acless << msg if msg.ack_chor.nil? 
    end
    puts "There are #{acless.size} Messages with no AC:"
    acless.each { |a| puts (a&.trigger&.code || 'Response to ?') }
  end
  
  def analyze_messages
    v2.message_types.each do |code, mt|
      unless mt.code
        puts mt.messages.map(&:section).inspect
        raise "No code for message type"
      end
    end
        
    msgs = v2.messages.select { |m| m.trigger&.status != 'W' }
    msgs.each do |msg|
      next if msg.trigger&.code.to_s =~ /^E3(0|1)$/
      if msg.message_type
        # puts msg.code
      else
        puts msg.code + Rainbow(' No Type!').red
      end
    end
  end
  
  def analyze_sections
    v2.sections.each do |num, hash|
      obj   = hash[:obj]
      fors  = hash[:for] || []
      texts = fors.select { |x| x.is_a?(V2AD::Text) }
      if !obj
        puts Rainbow("No obj for #{num}").red
        next
      end
      if texts.size == 1
        txt = texts.first
        if txt.lines.any?
          # puts Rainbow("#{num}").green
        else
          puts Rainbow("No lines in text for #{num}: ").orange + obj.title
        end
        next
      end
      if texts.size == 0
        puts Rainbow("No text for #{num}").orange
      else # multiple texts
        puts Rainbow("Multiple texts for #{num}").yellow
      end
    end
  end
  
  def analyze_seg_seqs
    counter = 0
    v2.seg_seqs.each do |ss|
      if ss.segments.first.optional
        ms = ss.structure
        puts "#{ms.code} in section #{ms.messages.map(&:section)} has optional first segment in a group"
        counter += 1
      end
    end
    puts counter.to_s
  end
  
  def analyze_data_types
    dts = v2.datatypes
    puts dts.size
    dts.each do |code, dt|
      # puts dt.code
    end
    
  end
    
  
end
