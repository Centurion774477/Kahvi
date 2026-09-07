

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
    when /enforce\s+(\'|\")\s*(?<id>.*)\s*(\'|\")?as\s+a\s+(?<type>.*)$/
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
    else
        return {
            type: :coffeescript,
            value: line
        }
    end
end

def generateEventListener token
  return <<~END
    document.getElementById('#{token[:id]}').addEventListener '#{token[:event_type]}', () ->
  END
end

def generateEnforcement token
    snippet = case token[:enforcement_type]
    when "string", "word"
        <<-END
        unless document.getElementById('#{token[:id]}.value == /^[a-zA-Z]+$/')
            alert("input rejected: it must be a word.")
            return
        END
    when "integer", "number"
        <<-END
        unless document.getElementById('#{token[:id]}.value == /^[0-9]+$/')
            alert("input rejected: it must be a number.")
            return
        END
    end
  return snippet
end

def generateElementAssignment token
  return <<~END
    #{token[:variable]} = document.getElementById '#{token[:id]}'
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

def generate token
    snippets = []

    snippet = case token[:type]
    when :event_listener     then generateEventListener token
    when :input_enforcement  then generateEnforcement token
    when :element_assignment then generateElementAssignment token
    when :hide               then generateHideElement token
    when :display            then generateDisplayElement token
    when :coffeescript       then token[:value]
    end

    snippets << snippet
    return snippets
end

file_to_read_from = ARGV[0]

if file_to_read_from.nil? then fail "You must provide an input file." end

lines        = File.readlines(file_to_read_from)
tokens       = lines.map { |line| lex line.chomp }
# lines.map { |line| p line }
snippets     = tokens.map { |token| generate token }

file_to_write_to = ARGV[1]

if file_to_write_to.nil? then fail "You must provide an output file." end

File.open(file_to_write_to, 'w') do |file|
    snippets.each {|snippet| file.puts snippet}
end

puts "Done brewing. Enjoy your CoffeeScript."

# eventually I'll have it transpile the CoffeeScript too so it returns JavaScript
