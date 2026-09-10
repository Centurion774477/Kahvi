

def lex line
    case line
    when /when\s+(\'|\")\s*(?<id>[^'"]*)\s*(\'|\")\s+is\s+(?<type>\w+)\s+->$/
        unless %w|clicked submitted highlighted mousedover unhighlighted mouseoff typed typing changed|.include?($~[:type])
          fail "Invalid type assigned to an event listener: #{$~[:type]} "
        end

        return {
        type: :event_listener,
        id: $~[:id],
        event_type: $~[:type]
        }
    when /enforce\s+\'(?<id>.*)\'\s+as\s+a\s+(?<type>.*)$/
        unless %w|string word integer number|.include?($~[:type])
          fail "Invalid type assigned to an enforce statement: #{$~[:type]} "
        end

        return {
        type: :input_enforcement,
        id: $~[:id],
        enforcement_type: $~[:type]
        }
    when /(?<variable>.*)\s+refers\s+to\s+(?<id>.*)$/
        return {
            type: :element_assignment,
            variable: $~[:variable],
            id: $~[:id]
        }
    when /hide\s+(?<variable>.*)$/
        return {
            type: :hide,
            variable: $~[:variable]
        }
    when /display\s+(?<variable>.*)$/
    return {
        type: :display,
        variable: $~[:variable]
    }
    when /^(?<new_var>.*)\s+=\s+(?<variable>.*)\s+as\s+(a|an)\s+(?<type>.*)$/
      return {
        type: :type_mutation,
        variable: $~[:variable],
        new_type: $~[:type],
        new_var: $~[:new_var]
      }
    when /^if\s+(?<part_1>.+?)\s+aint\s+(?<part_2>.+)$/
      return {
        type: :aint_condition,
        condition_one: $~[:part_1],
        condition_two: $~[:part_2]
      }
    when /^perform\s+(?<label>\w+)$/
      return {
        type: :perform,
        label: $~[:label]
      }
    when /^end$/
      return {
        type: :end
      }
    when /kahvi_confirm\s+(?<message>.*)$/
      return {
        type: :kahvi_confirm,
        message: $~[:message]
      }
    when /(?<function_name>.*)\s+does$/
      return {
        type: :alternate_function,
        name: $~[:function_name]
      }
    when /get\s+(?<element>.*)/
      return {
        type: :get_element,
        element: $~[:element]
      }
    when /^(?<variable>.*)\s+=\s+right\s+now\s+in\s+(?<type>(hours|minutes|seconds|full))/
      return {
        type: :right_now,
        time: $~[:type],
        variable: $~[:variable]
      }
    else
      return {
        type: :coffeescript,
        value: line
      }
    end
end


def generateEventListener token
  event_type = token[:event_type]
  coffeescript_event = case event_type
  when 'clicked'                   then 'click'
  when 'submitted'                 then 'submit'
  when 'highlighted', 'mousedover' then 'mouseover'
  when 'unhighlighted', 'mouseoff' then 'mouseout'
  when 'typed', 'typing'           then 'input'
  when 'changed'                   then 'change'
  else event_type
  end

  return <<~END
    document.getElementById('#{token[:id]}').addEventListener '#{coffeescript_event}', () ->
  END
end

def generateEnforcement token
    snippet = case token[:enforcement_type]
    when "string", "word"
        <<~END
        if document.getElementById('#{token[:id]}').value == '' or document.getElementById('#{token[:id]}').value == null
          alert("Input rejected: input is empty.")
          return
        unless document.getElementById('#{token[:id]}').value == /^[a-zA-Z]+$/
          alert("input rejected: it must be a word.")
          return
        END
    when "integer", "number"
        <<~END
        if document.getElementById('#{token[:id]}').value == '' or document.getElementById('#{token[:id]}').value == null
          alert("Input rejected: input is empty.")
          return
        unless document.getElementById('#{token[:id]}').value == /^[0-9]+$/
          alert("input rejected: it must be a number.")
          return
        END
    end
  return snippet
end

def generateElementAssignment token
  return <<~END
    #{token[:variable]} = document.getElementById #{token[:id]}
  END
end

def generateHideElement token
  return <<~END
    #{token[:variable]}.style.display = 'none'
  END
end

def generateDisplayElement token
  return <<~END
    #{token[:variable]}.style.display = 'block'
  END
end

def generateTypeMutation token
  return <<~END
    #{token[:new_var]} = #{token[:new_type].capitalize}(#{token[:variable]})
  END
end

def generateAintCondition token
  return <<~END
    if #{token[:condition_one]} isnt #{token[:condition_two]}
  END
end

def generatePerform token
  $inFunction = true
  $lastFunctionName = token[:label]
  return <<~END
    #{token[:label]} = () ->
  END
end

def generateEnd 
  unless $inFunction
    puts "Unexpected end"
    exit
  end

  if $lastFunctionName.nil?
    puts "Something went wrong"
    exit
  end

  $inFunction = false

  snippet = <<~END
    #{$lastFunctionName}()
  END

  $lastFunctionName = nil
  return snippet
end

def generateKahviConfirm token
  return <<~END
    unless confirm(#{token[:message]})
      return
  END
end

# eventually add a way to add arguments to these functions
def generateAlternateFunction token
  return <<~END
    #{token[:name]} = () ->
  END
end

# get saveButton
def generateGetElement token
  variable = token[:element]
  element_id = variable.gsub(/([A-Z])/, '-\1').downcase
  return <<~END
    #{variable} = document.getElementById '#{element_id}'
  END
end

# hours|minutes|seconds|full
def generateRightNow token
  case token[:time]
  when 'hours'
    return <<~END
      now = new Date()
      #{token[:variable]} = now.getHours()
    END
  when 'minutes'
    return <<~END
      now = new Date()
      #{token[:variable]} = now.getMinutes()
    END
  when 'seconds'
    return <<~END
      now = new Date()
      #{token[:variable]} = now.getSeconds()
    END
  when 'full'
    return <<~END
      now = new Date()
      hours = now.getHours()
      minutes = now.getMinutes()
      seconds = now.getSeconds()
      #{token[:variable]} = "\#{hours}:\#{minutes}:\#{seconds}"
    END
  end
end

$lastFunctionName = nil
$inFunction       = false # I couldn't care less about this being "bad"

def generate token
    snippets = []

    snippet = case token[:type]
    when :event_listener     then generateEventListener token
    when :input_enforcement  then generateEnforcement token
    when :element_assignment then generateElementAssignment token
    when :hide               then generateHideElement token
    when :display            then generateDisplayElement token
    when :type_mutation      then generateTypeMutation token
    when :aint_condition     then generateAintCondition token
    when :perform            then generatePerform token
    when :end                then generateEnd()
    when :kahvi_confirm      then generateKahviConfirm token
    when :alternate_function then generateAlternateFunction token
    when :get_element        then generateGetElement token
    when :right_now          then generateRightNow token
    when :coffeescript       then token[:value]
    end

    snippets << snippet
    return snippets
end

def generateCoffeeScript file_to_read_from, file_to_write_to
  lines        = File.readlines(file_to_read_from)
  tokens       = lines.map { |line| lex line.chomp }
  snippets     = tokens.map { |token| generate token }

  if file_to_write_to.nil? then fail "You must provide an output file." end

  File.open(file_to_write_to, 'w') do |file|
    snippets.each do |snippet| 
      file.puts snippet
    end
  end
end

# compile
def outputCoffeeScript file_in, file_out
  generateCoffeeScript file_in, file_out
  puts "Done brewing. Enjoy your CoffeeScript."
end

# full_send
def outputJavaScript file_in, file_out
  generateCoffeeScript file_in, file_out

  `coffee --compile #{file_out}`
end

# generate
# this will need refactoring later. Right now it just dumps everything into one directory
def outputPage name
  File.open("#{name}.html", 'w') do |file|
    file.puts <<~END
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">

          <link rel="stylesheet" href="#{name}.css">
          <title>#{name.capitalize}</title>
      </head>
      <body>

      <!--Hyvää koodausta, veli! - French Press CoffeeScript-->

      <h1>#{name.capitalize}</h1>

      <script src="#{name}.js"></script>
      </body>
      </html>
    END
  end

  File.open("#{name}.frenchpress", 'w') do |file|
    file.puts <<~END
      # Hei! Here are some of the features of FPCS you should know:
      # 
      # use `hide x` to hide an element; x.style.display = 'none'
      # the opposite `display x` displays an element; x.style.display = 'block'
      # 
      # use `get someElement` to fetch an html element. It compiles to: someElement = document.getElementById 'some-element'
      # use kahvi_confirm "message" to stop the execution of a function if the user doesn't confirm.
      # 
      # Also remember the commands used to parse this file into JavaScript or CoffeeScript respectively:
      # fp full_send #{name}.frenchpress
      # 
      # fp compile #{name}.frenchpress
      #
      # Happy programming! Hei Hei!
    END
  end

  File.open("#{name}.styl", 'w') do |file|
    file.puts <<~END
      /* 
      Stylus docs: https://stylus-lang.com/docs/
      Happy styling!
      */
    END
  end

  File.open("french_press_master.sh", 'a') do |file|
    file.puts <<~END
      fp full_send #{name}.frenchpress
      stylus #{name}.styl
    END
  end
end

# what-is-kahvi
def outputInformation
  puts "foobar; work in progress"
  exit
end

command           = ARGV[0]
file_to_read_from = ARGV[1]
file_to_write_to  = ARGV[2]

if file_to_read_from.nil? 
  if command == "generate"
    puts "You must provide a name for the page"
    exit
  elsif command == "what-is-kahvi"
    return # what-is-kahvi doesn't require any arguments
  else 
    puts "You must provide an input file."
    exit
  end
end




case command
when 'full_send' 
  if file_to_write_to.nil?
    puts "No output file was provided."
    exit
  end

  unless File.extname(file_to_write_to) == '.js'
    puts "Your file extension must be .js -- you passed #{File.extname(file_to_write_to)}"
    exit
  end

  outputJavaScript file_to_read_from, file_to_write_to
when 'compile' 
  if file_to_write_to.nil?
    puts "No output file was provided."
    exit
  end
  unless File.extname(file_to_write_to) == '.coffee'
    puts "Your file extension must be .coffee -- you passed #{File.extname(file_to_write_to)}"
    exit
  end
  outputCoffeeScript file_to_read_from, file_to_write_to
when 'generate'      then outputPage file_to_read_from
when 'what-is-kahvi' then outputInformation()
else 
  puts "Invalid command: #{command}. Type 'what-is-kahvi' for help"
  exit
end

