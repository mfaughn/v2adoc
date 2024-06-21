require_relative 'extract/utils'
module V2AD
  module_function
  
  def markdownize
    # chapters = %w{1 2 2A 3 4 4A 5 6 7 8 9 10 11 12 13 14 15 16 17}
    # chapters = %w{4A}
    chapters.each do |ch|
      # next unless ch == '4'
      chapter_dir = File.join(adoc_dir, ch)
      files = Dir["#{chapter_dir}/*"]
      FileUtils.mkdir_p(markdown_ch_dir(ch))
      files.each do |adoc_file|
        downdoc(adoc_file, ch)
      end
    end
  end
  
  def downdoc(adoc_file, ch = nil)
    md_dir = FileUtils.mkdir_p(markdown_ch_dir(ch))
    md = File.join(md_dir, File.basename(adoc_file).sub(/adoc$/, 'md'))    
    cmd = "npx downdoc -o #{md} #{adoc_file}"
    stdout, stderr, status = Open3.capture3(cmd)
    unless status.success?
      puts Rainbow(adoc_file).orange
      puts stdout if stdout.to_s.strip[0]
      puts stderr if stderr.to_s.strip[0]
    end
  end
  
  def markdownizetest
    adoc_file = File.join(test_dir, 'test.adoc')
    # adoctor(file)
    cmd = "asciidoctor '#{adoc_file}'"
    stdout, stderr, status = Open3.capture3(cmd)
    # unless status.success?
      puts Rainbow(adoc_file).orange
      puts stdout if stdout.to_s.strip[0]
      puts stderr if stderr.to_s.strip[0]
    # end
  end
end
V2AD.markdownize
# V2AD.htmlizetest
