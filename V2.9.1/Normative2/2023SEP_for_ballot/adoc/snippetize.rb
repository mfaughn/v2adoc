require 'fileutils'
require 'rainbow'
# chapters = %w{1 2 2A 3 4 4A 5 6 7 8 9 10 11 12 13 14 15 16 17}
chapters = %w{2}
adoc_dir = __dir__

chapters.each do |ch|
  # next # REMOVE FIXME
  # next unless ch == '17'
  chapter_dir = File.join(adoc_dir, ch)
  FileUtils.mkdir_p chapter_dir
  snippet_title = nil
  snippet = []
  snippet_file = nil
  adoc = File.join(adoc_dir, "#{ch}.adoc")
  File.readlines(adoc).each do |line|
    if line =~ /^\s*=+\s+\*?\d+A?(\.\d+)+\*?/
      snippet_title = line.gsub(/^\s*=+\s*/, '').gsub('*', '').gsub('/', '_slash_').chomp.strip.slice(/^\d+A?(\.\d+)+/)
      puts line unless snippet_title
      # puts snippet_title
      # open new file
      snippet_file.close if snippet_file
      puts Rainbow(File.basename(snippet_file)).green if snippet_file
      
      filename = File.join(chapter_dir, snippet_title + '.adoc')
      snippet_file = File.open(filename, 'w+')
    end
    if snippet_file
      snippet_file.puts line
    else
      puts Rainbow(ch).orange
      puts Rainbow(line).red
    end
  end
  snippet_file.close
end


chapters.each do |ch|
  next # REMOVE if you need to tweak this to snippetize a targetted selection of sections.
  chapter_dir = File.join(adoc_dir, ch)
  FileUtils.mkdir_p chapter_dir
  snippet_title = nil
  snippet = []
  snippet_file = nil
  adoc = File.join(adoc_dir, "#{ch}.adoc")
  File.readlines(adoc).each do |line|
    if line =~ /^\s*=+\s+\*?\d+A?(\.\d+)+\*?/
      snippet_title = line.gsub(/^\s*=+\s*/, '').gsub('*', '').gsub('/', '_slash_').chomp.strip.slice(/^\d+A?(\.\d+)+/)
      puts line unless snippet_title
      # puts Rainbow(snippet_title).lime
      # puts snippet_title
      # open new file
      snippet_file.close if snippet_file
      puts Rainbow(File.basename(snippet_file)).green if snippet_file
      
      filename = File.join(chapter_dir, snippet_title + '.adoc')
      snippet_file = File.open(filename, 'w+') if snippet_title =~ /16\.4\.6\./
    end
    if snippet_file
      snippet_file.puts line unless snippet_file.closed?
    else
      # puts Rainbow(ch).orange
      # puts Rainbow(line).red
    end
  end
  snippet_file.close
end
  
#
# FileUtils.mkdir_p adoc_dir
# html_dir = File.expand_path('V2.9.1/Normative2/2023SEP_for_ballot/html', __dir__)
# FileUtils.mkdir_p html_dir
# # puts File.exist? adoc