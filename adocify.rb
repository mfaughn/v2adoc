require 'fileutils'
# chapters = %w{1 2 2A 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17}
chapters = %w{3}
source_dir = File.expand_path('V2.9.1/Normative2/2023SEP_for_ballot/Parse', __dir__)
# puts dir
# puts File.exist? dir
adoc_dir = File.expand_path('V2.9.1/Normative2/2023SEP_for_ballot/adoc', __dir__)
FileUtils.mkdir_p adoc_dir
html_dir = File.expand_path('V2.9.1/Normative2/2023SEP_for_ballot/html', __dir__)
FileUtils.mkdir_p html_dir
# puts File.exist? adoc
chapters.each do |ch|
  # next unless ch == '17'
  docx = File.join(source_dir, "#{ch}.docx")
  adoc = File.join(adoc_dir,   "#{ch}.adoc")
  # html = File.join(html_dir,   "#{ch}.html")
  cmd = "pandoc #{docx} -f docx -t asciidoc --wrap=none --markdown-headings=atx --extract-media=extracted-media -o #{adoc}"
  system cmd
  cmd = "asciidoctor -D #{html_dir} #{adoc}"
  system cmd
end
