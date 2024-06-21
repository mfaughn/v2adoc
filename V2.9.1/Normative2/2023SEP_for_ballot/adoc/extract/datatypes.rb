require_relative 'utils'
require_relative 'v2'
module V2AD
  module_function
  def extract_datatypes(verbose = nil)
    # dir = File.join(adoc_dir, '2A')
    files = Dir["#{adoc_dir('2A')}/*"]
    # first get all datatype table sections
    files.each do |adoc_file|
      base_section   = adoc_file.sub('.adoc', '')
      section_number = File.basename(base_section)
      lines          = File.readlines(adoc_file)
      section_obj    = V2AD::Section.new(section_number, lines.dup)
      def_tables = section_obj.tables.select { |tbl| tbl.type == :datatype_definition }
            
      if def_tables.size > 1
        section_obj.display(content:true)
        section_obj.tables.each(&:display)
        raise "Data Type tables problem"
      end
      # puts "Created section_obj for #{section_obj.num}"
      
      def_table = def_tables.first
      if def_table        
        ttl    = section_obj.title
        rows   = def_table.rows[1..-2]
        header = lines.shift
        puts Rainbow(ttl).lime if verbose
        x = ttl.strip.gsub(/^=+\s*/, '').sub(/^2A\.\d+\.\d+/, '').strip
        code, name = x.split(/-|–/).map(&:strip)
        code = code.delete('*')
        code = 'Varies' if code =~ /varies/i
        if code.strip.empty?
          raise "Datatype section with no code: #{lines.first}"
        end
        
        dt = V2AD.v2.datatypes[code]
        dt ||= V2AD::Datatype.new(code, section_obj, name)
        puts Rainbow(dt.section.object_id).magenta if dt.code == 'AD'
        dt.name ||= name
        
        rows.each do |row_str|
          puts Rainbow(row_str).yellow if verbose
          row = split_row(row_str)
          dt.array_type = true if row.first =~ /\.\.\./
          dt.add_component(V2AD::Component.new(row, dt)) if row.first =~ /^\d+\.?$/
        end
        # puts Rainbow(code).magenta + ' ' + section_number if table.size < 2
        # puts Rainbow(code).coral + ' ' + section_number if table.size > 1

        # pp dt.components
        # puts Rainbow(code).green + ' ' + name
        subfiles = files.select { |f| f =~ /#{base_section}\.\d/ }.sort_by { |f| f.sub(base_section + '.', '').sub('.adoc', '').to_i }.reject { |f| f =~ /\.0\.adoc/ }
        subfiles.each do |sf|
          sf_lines = File.readlines(sf)
          seq = File.basename(sf).sub('.adoc', '').split('.').last
          comp = dt.components.find { |c| c.seq == seq }
          comp_section = File.basename(sf).sub('.adoc', '')
          v2ad_section = V2AD.v2.sections[comp_section][:obj]
          # puts Rainbow(comp_section).cyan
          comp.section = v2ad_section
          l1 = sf_lines.dup.first.sub(/^=+/, '').strip
          unless l1 =~ /#{comp.datatype}/ && l1 =~ /#{comp.section.num}/ && l1 =~ /#{comp.name}/i
            puts "#{comp.section.num} #{comp.name} (#{comp.datatype})"
            puts Rainbow(l1).yellow
            # puts Rainbow(sf_lines).coral
          end
          if comp.name_note
            if comp.withdrawn
              # puts Rainbow("#{comp.section.num} #{comp.name}(#{comp.name_note}) (#{comp.datatype})").orange
            else
              # puts Rainbow("#{comp.section.num} #{comp.name}(#{comp.name_note}) (#{comp.datatype})").gold
            end
          end

        end        
      end
    end
    
    # Replace string value with DataType object.  Couldn't do this earlier because we had not yet created all of the data types
    V2AD.v2.datatypes.each do |code, dt|
      if dt.components.size == 1
        dt.components.first.datatype = dt
        dt.components.first.display(:orange)
      else
        dt.components.each do |comp|
          next if comp.withdrawn
          cdt = V2AD.v2.datatypes[comp.datatype]
          raise "No datatype for #{dt.code}.#{comp.seq} -- #{comp.datatype}" unless cdt
          comp.datatype = cdt
        end
      end
    end
  end

  def find_or_create_datatype(str, section)
    return nil if str.empty?
    raise "Why should I look for data type #{str} from #{section.number}" if str =~ /-/
    # puts "find_or_create_datatype: #{str} from #{section.num}"
    str = str.delete('*')
    str = 'Varies' if str =~ /varies/i
    dt = V2AD.v2.datatypes[str]
    return dt if dt
    dt = V2AD::Datatype.new(str, section)
    V2AD.v2.datatypes[str] = dt
    find_or_create_datatype(str, section)
  end
end
