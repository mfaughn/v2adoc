module V2AD

  class DataElement < V2Obj
    attr_accessor :name, :item_number, :min_length, :max_length, :c_length, :may_truncate, :datatype_varies, :datatype, :definition_text, :table, :fields
    def initialize(item_number, min_length, max_length, c_length, datatype, opt, section)
      @item_number = item_number
      @min_length  = min_length
      @max_length  = max_length
      @c_length    = c_length
      @fields      = []
      if datatype&.[](0)
        self.datatype = V2AD.find_or_create_datatype(datatype, section)
      else
        raise if opt != 'W'
      end
      V2AD.register_to_section(section, self)
      # datatype_varies = true unless datatype
    end
    
    def datatype=(dt)
      @datatype = dt
      dt.data_elements << self
    end
    
    def sections
      fields.map(&:section).uniq
    end
    
    def set_table(tbl, segment_code, section)
      @table = V2AD.remove_links(tbl, section)
      # puts "DataElement table: #{tbl} --> #{@table}" if tbl =~ /\\\\/
      V2AD.add_table(self.table, "#{segment_code} from #{section.num}")
    end
    
    def diff_str
      [attr_diff_str, def_diff_str].join("\n")
    end
    
    def attr_diff_str
      a = []
      a << "item_number:#{item_number},"
      a << "name:#{name},"
      a << "min_length:#{min_length},"
      a << "max_length:#{max_length},"
      a << "c_length:#{c_length},"
      a << "may_truncate:#{may_truncate},"
      a << "dt_varies:#{datatype_varies},"
      a << "data_type:#{datatype&.code},"
      a << "table:#{table},"
      a.join("\n")
    end
    
    def def_diff_str
      "definition:#{definition_text}"
    end
    
    def json
      # return diff_str
      # unless datatype
      #   puts "No datatype for #{item_number} from #{fields.map { |f| f.owner.code + '-' + f.seq.to_s}.join(',') }"
      # end
      {item_number:item_number, name:name, min_length:min_length, max_length:max_length, c_length:c_length, may_truncate:may_truncate, dt_varies:datatype_varies, data_type:datatype&.code, table:table, definition:definition_text}.to_json
    end
  end
  
  module_function

  def add_data_element(de, code)
    V2.instance.data_elements[de.item_number] ||= {}
    V2.instance.data_elements[de.item_number][code] = de
  end

end
