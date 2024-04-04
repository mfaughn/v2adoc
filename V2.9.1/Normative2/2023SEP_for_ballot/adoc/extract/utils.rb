require 'fileutils'
require 'open3'
require 'rainbow'
module V2AD
  module_function
  
  def adoc_dir(ch = nil)
    dir = File.expand_path(ch ? File.join(__dir__, '..', ch.to_s) : __dir__)
    raise "NOPE: #{dir}" unless File.exist?(dir)
    dir
  end
  
  def test_dir
    File.expand_path('../test', __dir__)
  end
  
  def html_dir
    @html_dir ||= File.expand_path('../../html', __dir__)
  end
  
  def html_ch_dir(ch)
    ch ? File.join(html_dir, ch) : html_dir
  end
  
  def chapters
    %w{1 2A 3 4 4A 5 6 7 8 9 10 11 12 13 14 15 16 17}
  end
  
  def split_row(l)
    row = l.split('|').map(&:strip).map do |v|
      if v =~ /file:/
        v.gsub(/file.+\[/, '').sub(/\]$/, '')
      else
        v
      end
    end 
    row.shift if row.first == ''
    row
  end
  
  def subsection_files(section)
    ch = section.slice(/^\d+A?/)
    files = Dir["#{adoc_dir(ch)}/*.adoc"].select { |f| f =~ /#{section}/ }
  end
  
  def remove_empty_cells(str)
    # some legit cells end with a pipe char.  If so, it will be escaped.  Detect that and do not remove.
    str.gsub(/(?<!\\)\|\s*(?=\|)/, '')
  end
  
  def remove_underline(str)
    return str unless str =~ /underline/
    str = str.gsub(/\[.underline\]#(.+?)#/, '\1')
  end
  
  def remove_links(str, section = nil)
    return str if str =~ /\^~\\&/
    return str unless str =~ /:/
    if false #section =~ /4.5.3/
      verbose = true
      puts Rainbow(section).lawngreen + " #{str}"
    end
    str = remove_file_backslashes(str)
    show_backslashes(str, :red, :green)
    remove_directory_link(remove_file_link(remove_link_link(str, verbose), verbose), verbose)
  end
  
  def remove_file_backslashes(str)
    str = str.dup
    return str unless str =~ /:\\/
    # show_backslashes(str, :red, :yellow)
    str = str.delete('\\')
    str
  end
  
  def show_backslashes(str, color1 = nil, color2 = nil)
    color1 ||= :orange
    color2 ||= :white
    return unless str =~ /\\/
    chars = str.split('')
    puts '-----' + chars.map { |char| c = char.to_s; c == "\\" ? Rainbow(c).send(color1.to_sym) : Rainbow(c).send(color2.to_sym) }.join
  end
  
  def remove_file_link(str, verbose = false)
    _remove_link(str, :file, verbose)
  end
  
  def remove_link_link(str, verbose = false)
    _remove_link(str, :link, verbose)
  end
  
  def remove_directory_link(str, verbose = false)
    return str unless str =~ /[A-Z]:/
    type = str.slice(/[A-Z](?=:)/)
    return _remove_link(str, type, verbose)
    # str =~ /([A-Z]:\\\\.+?)(?=\[)/
    # link = $1
    # begin
    #   reggie = /#{link}\[(.+?)\]/
    # rescue ArgumentError => ae
    #   # puts Rainbow(ae.message).orange + " #{link}"
    #   success = _remove_link(str.delete("\\"), str.slice(/^[A-Z]/))
    #   # puts Rainbow(success).gold
    #   return success
    # end
    # # puts reggie.inspect
    # mm = reggie.match(str)
    # # pp mm
    # correct = $1
    # # puts Rainbow(correct).coral
    # ret = str.sub(/#{link}\[(.+?)\]/, '\1')
    # # puts Rainbow(ret).coral
    # ret
    
  end
  
  def _remove_link(str, type, verbose = false)
    return str unless str =~ /#{type}/
    str =~ /(#{type}:.+?)(?=\[)/
    link = $1
    return unless link
    puts "-----#{type}-----" if verbose
    # puts Rainbow(str).blue if verbose
    begin
      reggie = /#{link}\[(.+?)\]/
    rescue ArgumentError => ae
      # puts Rainbow(ae.message).orange + " #{link}" if verbose
      success = _remove_link(str.delete("\\"), type)
      # puts Rainbow(success).gold if verbose
      return success
    end      
    # puts Rainbow(reggie.inspect).aqua if verbose
    mm = reggie.match(str)
    # pp mm if verbose
    correct = $1
    # puts Rainbow(correct).coral if verbose
    ret = str.sub(/#{link}\[(.+?)\]/, '\1')
    puts Rainbow(ret).gold if verbose
    ret
  end
end
