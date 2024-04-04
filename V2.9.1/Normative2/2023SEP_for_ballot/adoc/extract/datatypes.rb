require_relative 'utils'
require_relative 'v2'
module V2AD
  module_function
  def extract_datatypes
    # dir = File.join(adoc_dir, '2A')
    files = Dir["#{adoc_dir('2A')}/*"]
    # first get all datatype table sections
    files.each do |adoc_file|
      base_section   = adoc_file.sub('.adoc', '')
      section_number = File.basename(base_section)
      lines          = File.readlines(adoc_file)
      section_obj    = V2AD::Section.new(section_number, lines.dup, section_number)
next# REMOVE
      # puts "Created section_obj for #{section_obj.num}"
      
      if lines.any? { |str| str =~ /\|===/ } 
        if lines.first =~ /===\s+2A\.\d+\.\d+\s+/
          x = lines.first.strip.gsub(/^=+\s*/, '').sub(/^2A\.\d+\.\d+/, '').strip
          code, name = x.split(/-|–/).map(&:strip)
          code = code.delete('*')
          code = 'Varies' if code =~ /varies/i
          if code.strip.empty?
            raise "Datatype section with no code: #{lines.first}"
          end
          dt = V2AD.v2.datatypes[code]
          dt ||= V2AD::Datatype.new(code, section_number, name)
          dt.name ||= name
          dt.section ||= section_number
          V2AD.v2.datatypes[code] = dt
          # puts Rainbow(code).green + ' ' + section_number
          dt.adoc_source = lines
          
          first_component_i = (lines.index  { |l| l =~ datatype_table_header_regex }) + 1
          table = []
          after_table_i = nil
          lines[first_component_i..-1].each_with_index do |l, i|
            # puts Rainbow(l).yellow
            if l =~ /\|===/
              after_table_i = i + 1
              break
            end
            row = split_row(l)
            dt.array_type = true if row.first =~ /\.\.\./
            table << row if row.first =~ /^\d+\.?$/
          end
          # puts Rainbow(code).magenta + ' ' + section_number if table.size < 2
          # puts Rainbow(code).coral + ' ' + section_number if table.size > 1
          table.each do |row|
            dt.components << V2AD::Component.new(row, code)
          end
          # pp dt.components
          # puts Rainbow(code).green + ' ' + name
          subfiles = files.select { |f| f =~ /#{base_section}\.\d/ }.sort_by { |f| f.sub(base_section + '.', '').sub('.adoc', '').to_i }.reject { |f| f =~ /\.0\.adoc/ }
          subfiles.each do |sf|
            sf_lines = File.readlines(sf)
            seq = File.basename(sf).sub('.adoc', '').split('.').last
            comp = dt.components.find { |c| c.seq == seq }
            comp_section = File.basename(sf).sub('.adoc', '')
            v2ad_section = V2AD.v2.sections[comp_section]
            begin
              v2ad_section[:for] << comp
            rescue
              puts "Section #{comp_section} problem"
              puts "Does section exist? #{!!v2ad_section}"
              raise
            end
            # puts Rainbow(comp_section).cyan
            comp.section = comp_section
            comp.adoc_source = sf_lines
            comp.text = Text.new(sf_lines, true)
            l1 = sf_lines.first.sub(/^=+/, '').strip
            unless l1 =~ /#{comp.datatype}/ && l1 =~ /#{comp.section}/ && l1 =~ /#{comp.name}/i
              # puts "#{comp.section} #{comp.name} (#{comp.datatype})"
              # puts Rainbow(l1).yellow
            end
          end
          
          dt.text = Text.new(lines[(after_table_i + first_component_i)..-1])
          # puts dt.text
        end
        
      end
    end
  end

  def find_or_create_datatype(str, section)
    return nil if str.empty?
    raise "Why should I look for data type #{str} from #{section}" if str =~ /-/
    # puts "find_or_create_datatype: #{str} from #{section}"
    str = str.delete('*')
    str = 'Varies' if str =~ /varies/i
    dt = V2AD.v2.datatypes[str]
    return dt if dt
    dt = V2AD::Datatype.new(str, section)
    V2AD.v2.datatypes[str] = dt
    find_or_create_datatype(str, section)
  end
end
