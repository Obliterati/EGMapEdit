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
  File.open(filename, 'w+') {|f| f.puts safe_text}
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

def eg_filename(filename)
 filename_frag = filename.split('/')
 eg_filename = ['history_new', '/provinces/', filename_frag[-1]].join.to_s
end

def history_string(filename)
  original_file = old_filename(filename)
  eg_file = eg_filename(filename)
  vanilla_tag = tag_getter(original_file)
  eg_tag = tag_getter(eg_file)
  extra_tags = cores_getter(original_file)


  #{extra_tags.map {|tag| "add_core = #{tag}\n"}.join}

  history = "1445.1.2 = {\nremove_core = #{ vanilla_tag }\ncontroller = #{ eg_tag }\nowner = #{ eg_tag }\n#{ getter(eg_file, 'religion') }#{ getter(eg_file, 'culture') }\n  } # EG/vanilla merge added by Obliterati with EGMapEdit"

  # YOU NOW NEED TO ACCOUNT FOR DEVELOPMENT ALTERATIONS
end

def full_writer(filename)
  File.open(filename, 'a') { |f| f.puts history_string(filename) }
end

puts 'cleaning files...'
Dir.foreach("history_output/provinces") do |file|
  begin
    puts "cleaned #{file}" if !is_hidden?(file)
    file_cleaner("history_output/provinces/#{file}") if !is_hidden?(file)

  end
end
puts 'files cleaned'

puts 'merging files...'
Dir.foreach("history_output/provinces") do |file|
  begin
   full_writer("history_output/provinces/#{file}") if !is_hidden?(file)
 rescue SystemCallError
  puts "FAILED: #{file} - SystemCallError"
  next
rescue NoMethodError
  puts "FAILED: #{file} - NoMethodError"
  next
rescue ArgumentError
  puts "FAILED: #{file} - ArgumentError"
  next
end
end
puts 'all files merged.'