require 'fileutils'
require 'pry-byebug'

def is_hidden?(filename)
  filename[0] == "."
end

def file_cleaner(filename)
  file = File.open(filename).drop(0)
  safe_text = file.each { |line| line.encode!(invalid: :replace)}
  safe_text.each_with_index do |line, index| 
    if line[0..3].to_i >= 1444
      first_history_line_number = index - 1
      safe_text = safe_text.slice!(0..first_history_line_number)
    end
  end
  safe_text.each_with_index do |line, index| 
    if line =~ /add_local_autonomy =/ || line =~ /estate/ || line =~ /fort_15th/ || line =~ /unrest/
      puts 'found minor info'
      safe_text = safe_text.slice(0..index-1) + safe_text.slice(index..-1)
    end
  end
  File.open(filename, 'w+') {|f| f.puts safe_text}
end

def file_reader(filename)
  begin
    file = File.open(filename).drop(0)
  rescue SystemCallError
    file = File.open(old_filename(filename)).drop(0)
  end
  safe_text = file.each { |line| line.encode!(invalid: :replace)}
  safe_text
end

def cores_getter(text)
  added_cores = text.select { |line| line =~ /(add_core = .{3})/ }
  tag_strings = added_cores.map { |core| core.to_s.split('=') }.flatten.select { |chunk| chunk =~ /([A-Z]{3})/}.map {|string| string.strip}
  tags = tag_strings.map {|tag| tag[0..2]}
end

def tag_getter(text)
 tag = text.find { |line| line =~ /(add_core = .{3})/ }
 if !tag
  tag = 'NIL'
else
  tag = tag.chomp.split[2]
end
tag
end

def getter(text, string)
  setting = text.find { |line| line =~ /#{string}/}
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

 original_text = file_reader(original_file)
 eg_text = file_reader(eg_file)

 vanilla_tag = tag_getter(original_text)
 eg_tag = tag_getter(eg_text)

 if eg_tag != 'NIL'
  history_string = "1445.1.2 = {\nremove_core = #{ vanilla_tag }\nadd_core = #{ eg_tag }\ncontroller = #{ eg_tag }\nowner = #{ eg_tag }\n#{ getter(eg_text, 'religion') }#{ getter(eg_text, 'culture') }} # EG/vanilla merge added by Obliterati with EGMapEdit"
else
  history_string = "1445.1.2 = {\n } #No changes from EGMapEdit"
end
history_string
end

def full_writer(filename)
  File.open(filename, 'a') { |f| f.puts history_string(filename) }
end

def full_run(directory)
  puts 'merging files...'
  system_call_errors = 0
  no_method_errors = 0
  argument_errors = 0
  count = Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count - 3
  Dir.foreach(directory) do |file|
    begin
      file_reader("#{directory}/#{file}") if !is_hidden?(file)
      full_writer("#{directory}/#{file}") if !is_hidden?(file)
    rescue SystemCallError
      puts "FAILED: #{file} - SystemCallError"
      system_call_errors += 1
      next
    rescue NoMethodError
      puts "FAILED: #{file} - NoMethodError"
      no_method_errors += 1
      next
    rescue ArgumentError
      puts "FAILED: #{file} - ArgumentError"
      argument_errors += 1
      next
    end
  end
  puts "\nAll files merged.  Errors as follows:\nSystemCallErrors: #{system_call_errors}\nNoMethodErrors: #{no_method_errors}\nArgumentErrors: #{argument_errors}\nof a total #{count} files"
  if system_call_errors == 0 && no_method_errors == 0 && argument_errors == 0
    puts "No errors!"
  end
end

# ACTUAL RUN

puts 'cleaning files...'
Dir.foreach("history_output/provinces") do |file|
  file_cleaner("history_output/provinces/#{file}") if !is_hidden?(file)
  puts "cleaned #{file}" if !is_hidden?(file)
end
puts 'files cleaned'

full_run("history_output/provinces")