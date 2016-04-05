require 'fileutils'
require 'pry-byebug'

def is_hidden?(filename)
  filename[0] == "."
end

def file_cleaner(filename, *writer)
  file = File.open(filename).drop(0)
  eg_entry_start = 0
  eg_entry_end = 0
  safe_text = file.each { |line| line.encode!(invalid: :replace)}
  safe_text.each_with_index do |line, index| 
    if line[0..7] == "1445.1.2" || line[0..7] == "1445.1.1"
      eg_entry_start = index
      safe_text.each_with_index do |line, index|
        if line[0] == "}"
          eg_entry_end = index
        end
      end
    end
  end

  if eg_entry_start != 0
    eg_entry = safe_text[eg_entry_start...(eg_entry_end+1)]
  else
    eg_entry = '# All changes implemented by Obliterati with EGMapEdit'
  end

  safe_text.each_with_index do |line, index| 
    if line[0..3].to_i >= 1444
      first_history_line_number = index - 1
      safe_text = safe_text.slice(0..first_history_line_number)
    end
  end

  safe_text.each_with_index do |line, index| 
    if line =~ /add_local_autonomy =/ || line =~ /estate =/ || line =~ /fort_15th = yes/ || line =~ /unrest =/
      puts "found minor info for #{filename}"
      safe_text = safe_text.slice(0..index-1) + safe_text.slice((index+1)..-1)
    end
  end

  safe_text.push(eg_entry)
  if writer == 'yes'
    File.open(filename, 'w+') {|f| f.puts safe_text}
  end
  safe_text
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

def discoveries_getter(text)
  discoveries = text.select { |line| line =~ /(discovered_by)/ }
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

def discoveries_writer(filename)
  old_text = file_reader(old_filename(filename))
  discoveries = discoveries_getter(old_text)
  first_history_line_number = 0
  
  text = file_cleaner(filename)
  text.each_with_index do |line, index| 
    if line[0] == 1
      first_history_line_number = index - 1
    end
  end
  if first_history_line_number != 0
    safe_text = text.slice(0..first_history_line_number) + discoveries + text.slice((first_history_line_number + 1)..-1)
  else
    final_line = text[-1]
    safe_text = text[0..-2] + discoveries
    safe_text.push(final_line)
  end
  # binding.pry
  File.open(filename, 'w+') {|f| f.puts safe_text}
  safe_text
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

Dir.foreach("history_new/provinces") do |file|
  if !is_hidden?(file)
    file_cleaner("history_new/provinces/#{file}")
    discoveries_writer("history_new/provinces/#{file}")
  end
end


# ACTUAL RUN

# puts 'cleaning files...'
# Dir.foreach("history_output/provinces") do |file|
#   if !is_hidden?(file)
#     file_cleaner("history_output/provinces/#{file}") 
#     puts "cleaned #{file}\n"
#   end
# end
# puts 'files cleaned'


# full_run("history_output/provinces")