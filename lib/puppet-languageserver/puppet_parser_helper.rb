module PuppetLanguageServer
  module PuppetParserHelper

    def self.remove_chars_starting_at(content, line_offsets, line_num, char_num, num_chars_to_remove)
      line_offset = line_offsets[line_num]
      raise if line_offset.nil?

      # Remove the offending character
      new_content = content.slice(0, line_offset + char_num - num_chars_to_remove) + content.slice(line_offset + char_num, content.length - num_chars_to_remove)

      new_content
    end

    def self.remove_char_at(content, line_offsets, line_num, char_num)
      remove_chars_starting_at(content, line_offsets, line_num, char_num, 1)
    end

    def self.get_char_at(content, line_offsets, line_num, char_num)
      line_offset = line_offsets[line_num]
      raise if line_offset.nil?

      absolute_offset = line_offset + (char_num - 1)

      content[absolute_offset]
    end

    def self.insert_text_at(content, line_offsets, line_num, char_num, text)
      # Insert text after where the cursor is
      # This helps due to syntax errors like `$facts[]` or `ensure =>`
      line_offset = line_offsets[line_num]
      raise if line_offset.nil?
      # Insert the text
      new_content = content.slice(0, line_offset + char_num) + text + content.slice(line_offset + char_num, content.length - 1)

      new_content
    end

    def self.line_offsets(content)
      # Calculate all of the offsets of \n in the file
      line_offsets = [0]
      line_offset = -1
      loop do
        line_offset = content.index("\n", line_offset + 1)
        break if line_offset.nil?
        line_offsets << line_offset + 1
      end
      line_offsets
    end

    def self.get_line_at(content, line_offsets, line_num)
      # Get the text of the designated line
      start_index = line_offsets[line_num]
      if line_offsets[line_num + 1].nil?
        content.slice(start_index, content.length - start_index)
      else
        content.slice(start_index, line_offsets[line_num + 1] - start_index - 1)
      end
    end

    def self.estimate_object_under_cursor(content, line_num, char_num, disallowed_classes = [])
      process_ast_for_object(content, line_num, char_num, true, true, disallowed_classes)
    end

    def self.exact_object_under_cursor(content, line_num, char_num, disallowed_classes = [])
      process_ast_for_object(content, line_num, char_num, false, false, disallowed_classes)
    end

    def self.process_ast_for_object(content, line_num, char_num, multiple_attempts, after_keypress, disallowed_classes)
      # Use Puppet to generate the AST
      parser = Puppet::Pops::Parser::Parser.new

      # Calculating the line offsets can be expensive and is only required
      # if we're doing mulitple passes of parsing
      line_offsets = line_offsets(content) if multiple_attempts

      result = nil
      move_offset = 0
      %i[noop remove_word try_quotes try_quotes_and_comma remove_char].each do |method|
        new_content = nil
        case method
        when :noop
          new_content = content
        when :remove_char
          new_content = remove_char_at(content, line_offsets, line_num, char_num)
          move_offset = -1
        when :remove_word
          next_char = get_char_at(content, line_offsets, line_num, char_num)

          while /[[:word:]]/ =~ next_char
            move_offset -= 1
            next_char = get_char_at(content, line_offsets, line_num, char_num + move_offset)

            break if char_num + move_offset < 0
          end

          new_content = remove_chars_starting_at(content, line_offsets, line_num, char_num, -move_offset)
        when :try_quotes
          # Perhaps try inserting double quotes.  Useful in empty arrays or during variable assignment
          # Grab the line up to the cursor character + 1
          line = get_line_at(content, line_offsets, line_num).slice!(0, char_num + 1)
          if line.strip.end_with?('=') || line.end_with?('[]') # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
            new_content = insert_text_at(content, line_offsets, line_num, char_num, "''")
          end
        when :try_quotes_and_comma
          # Perhaps try inserting double quotes with a comma.  Useful resource properties and parameter assignments
          # Grab the line up to the cursor character + 1
          line = get_line_at(content, line_offsets, line_num).slice!(0, char_num + 1)
          if line.strip.end_with?('=>') # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
            new_content = insert_text_at(content, line_offsets, line_num, char_num, "'',")
          end
        else
          raise("Unknown parsing method #{method}")
        end
        # if we have no content to parse, try the next method.
        next if new_content.nil?

        begin
          result = parser.parse_string(new_content, '')
          break
        rescue Puppet::ParseErrorWithIssue => _exception
          next if multiple_attempts
          raise
        end
      end
      raise('Unable to parse content') if result.nil?

      # Convert line and char nums (base 0) to an absolute offset
      #   result.line_offsets contains an array of the offsets on a per line basis e.g.
      #     [0, 14, 34, 36]  means line number 2 starts at absolute offset 34
      #   Once we know the line offset, we can simply add on the char_num to get the absolute offset
      #   If during paring we modified the source we may need to change the cursor location
      begin
        line_offset = result.line_offsets[line_num]
      rescue StandardError => _e
        line_offset = result['locator'].line_index[line_num]
      end
      abs_offset = line_offset + char_num + move_offset
      # Typically we're completing after something was typed, so go back one
      # char if we not at the beginning of a line
      abs_offset -= 1 if after_keypress && char_num > 0

      model_path_struct = Struct.new(:model, :path)
      item, path = recurse_ast(result.model, abs_offset, disallowed_classes)
      return nil, nil if item.nil?

      return item, path
    end
    private_class_method :process_ast_for_object

    def self.recurse_ast(item, abs_offset, disallowed_classes, indent = 0, path = [])
      this_path = path + [item]

      if item.respond_to? :eAllContents
        # Puppet 4
        item.eContents.select do |child|
          child_item = recurse_ast(child, abs_offset, disallowed_classes, indent + 1, this_path)
          return child_item, child_path unless child_item.nil?
        end
      else
        # Puppet 5+
        item._pcore_contents do |child|
          child_item, child_path = recurse_ast(child, abs_offset, disallowed_classes, indent + 1, this_path)
          return child_item, child_path unless child_item.nil?
        end
      end
      if is_valid_item?(item, abs_offset, disallowed_classes)
        return item, path
      else
        return nil, nil
      end
    end

    # # Debugging only method
    # def self.draw_ast(item, indent = 0, abs_offset, disallowed_classes)
    #   puts "--- Finding offset #{abs_offset} ----------------- AST \n ( ) Invalid  (+) Valid Item" if indent.zero?
    #   indentText = "  " * indent
    #   if is_valid_item?(item, abs_offset, disallowed_classes)
    #     indentText += "(+)"
    #   else
    #     indentText += "( )"
    #   end

    #   off = item.respond_to?(:offset) ? item.offset : '???'
    #   length = item.respond_to?(:length) ? item.length : '???'
    #   line = item.respond_to?(:line) ? item.line : '???'
    #   pos = item.respond_to?(:pos) ? item.pos : '???'
    #   off = off.nil? ? 'nil' : off
    #   length = length.nil? ? 'nil' : length

    #   puts "#{indentText} #{item.class.to_s} off:#{off} len:#{length} (#{line},#{pos}) [#{item.object_id}]"

    #   if item.respond_to? :eContents
    #     # Puppet 4
    #     item.eContents.select { |child| draw_ast(child, indent + 1, abs_offset,disallowed_classes) }
    #   else
    #     # Puppet 5+
    #     item._pcore_contents { |child| draw_ast(child, indent + 1, abs_offset,disallowed_classes) }
    #   end
    #   puts "---------------------------------------------- AST" if indent.zero?
    # end
    # private_class_method :draw_ast

    def self.is_valid_item?(item, abs_offset, disallowed_classes)
      return false if item.nil?
      return false if !item.respond_to?(:offset) || item.offset.nil?
      return false if !item.respond_to?(:length) || item.length.nil? || item.length.zero?
      return false if disallowed_classes.include?(item.class)
      abs_offset >= item.offset && abs_offset <= item.offset + item.length
    end
    private_class_method :is_valid_item?
  end
end
