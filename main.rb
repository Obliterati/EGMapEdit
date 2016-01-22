require 'fileutils'

def is_hidden?(filename)
  filename[0] == "."
end

def file_cleaner(filename)
  file = File.open(filename).drop(2)
  safe_text = file.each { |line| line.encode!(invalid: :replace)}
  safe_text.each_with_index do |line, index| 
    if line[0..3].to_i >= 1444
      first_history_line_number = index - 1
      safe_text = safe_text.slice!(0..first_history_line_number)
    end
  end
  safe_text
end

def cores_getter(filename)
  safe_text = file_cleaner(filename)
  added_cores = safe_text.select { |line| line =~ /(add_core = .{3})/ }
  tag_strings = added_cores.map { |core| core.to_s.split('=') }.flatten.select { |chunk| chunk =~ /([A-Z]{3})/}.map {|string| string.strip}
  tags = tag_strings.map {|tag| tag[0..2]}
end

def tag_getter(filename)
  safe_text = file_cleaner(filename)
  tag = safe_text.find { |line| line =~ /(owner = .{3})/ }.chomp.split[2]
end

def getter(filename, string)
  safe_text = file_cleaner(filename)
  setting = safe_text.find { |line| line =~ /#{string}/}
  if setting != nil
    setting
  else
    "#{string} = 0"
  end
end

def old_filename(filename)
  filename_frag = filename.split('/')
  old_filename = ['history', '/provinces/', filename_frag[-1]].join.to_s
end

def history_string(filename)
  vanilla_tag = tag_getter(old_filename(filename))
  eg_tag = tag_getter(filename)
  extra_tags = cores_getter(old_filename(filename))
  history = "1445.1.2 = {\nremove_core = #{ eg_tag }\n#{extra_tags.map {|tag| "add_core = #{tag}\n"}.join}controller = #{ vanilla_tag }\nowner = #{ vanilla_tag }\n#{ getter(old_filename(filename), 'religion') }#{ getter(old_filename(filename), 'culture') }\n  } # EG/vanilla merge added by Obliterati with EGMapEdit"
end

def full_writer(filename)
  File.open(filename, 'a') { |f| f.puts history_string(filename) }
end


puts 'merging files...'
Dir.foreach("history_output/provinces") do |file|
  begin
   full_writer("history_output/provinces/#{file}") if !is_hidden?(file)
 rescue SystemCallError
  puts "FAILED: #{file} - SystemCallError"
  next
 rescue NoMethodError
  puts "Failed: #{file} - NoMethodError"
  next
 rescue ArgumentError
  puts "FAILED: #{file} - ArgumentError"
  next
 end
end
puts 'all files merged.'