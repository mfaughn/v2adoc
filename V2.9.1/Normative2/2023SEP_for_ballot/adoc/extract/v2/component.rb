module V2AD

  class Component < V2Obj
    attr_accessor :seq, :len, :clen, :datatype, :opt, :table, :name, :comments, :sec_ref, :parent, :name_note, :withdrawn
    
    def initialize(row, parent_datatype)
      @section = section
      row = row.map { |x| x.strip == '' ? nil : x }
      @seq, @len, @clen, @datatype, @opt, tbl, name, @comments, @sec_ref = row
      @withdrawn = true if @opt == 'W'
      if name =~ /\(.+\)/
        @name = name.slice(/.+(?=\()/).strip
        @name_note = name.slice(/(?<=\().+(?=\))/).strip
      else
        @name = name
      end
        
      @table = V2AD.remove_links(tbl, section) if tbl
      # puts "Component table: #{tbl} --> #{@table}" if tbl =~ /\\\\/
      V2AD.add_table(self.table, "DT #{parent_datatype.code} from #{parent_datatype.section.num}") if self.table
    end
    
    def section=(section)
      @section = section
      V2AD.register_to_section(section, self)
    end
    
    def display(opts = nil)
      color = opts[:color]
      str = "#{parent_datatype.code}.#{seq} - #{name} (#{datatype.code})\n#{len}|#{clen}|#{opt}|#{table}|#{comments}"
      if color
        puts Rainbow(str).send(color.to_sym)
      else
        puts str
      end
    end
  end
  
end
