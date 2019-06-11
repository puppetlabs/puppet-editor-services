# frozen_string_literal: true

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

    def self.object_under_cursor(content, line_num, char_num, options)
      options = {
        :multiple_attempts   => false,
        :disallowed_classes  => [],
        :tasks_mode          => false,
        :remove_trigger_char => true
      }.merge(options)

      # Use Puppet to generate the AST
      parser = Puppet::Pops::Parser::Parser.new

      # Calculating the line offsets can be expensive and is only required
      # if we're doing mulitple passes of parsing
      line_offsets = line_offsets(content) if options[:multiple_attempts]

      result = nil
      move_offset = 0
      %i[noop remove_word try_quotes try_quotes_and_comma remove_char].each do |method|
        new_content = nil
        case method
        when :noop
          new_content = content
        when :remove_char
          next if line_num.zero? && char_num.zero?
          new_content = remove_char_at(content, line_offsets, line_num, char_num)
          move_offset = -1
        when :remove_word
          next if line_num.zero? && char_num.zero?
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
          result = parser.singleton_parse_string(new_content, options[:tasks_mode], '')
          break
        rescue Puppet::ParseErrorWithIssue
          next if options[:multiple_attempts]
          raise
        end
      end
      raise('Unable to parse content') if result.nil?

      # Convert line and char nums (base 0) to an absolute offset
      #   result.line_offsets contains an array of the offsets on a per line basis e.g.
      #     [0, 14, 34, 36]  means line number 2 starts at absolute offset 34
      #   Once we know the line offset, we can simply add on the char_num to get the absolute offset
      #   If during paring we modified the source we may need to change the cursor location
      if result.respond_to?(:line_offsets)
        line_offset = result.line_offsets[line_num]
      else
        line_offset = result['locator'].line_index[line_num]
      end
      abs_offset = line_offset + char_num + move_offset
      # Typically we're completing after something was typed, so go back one char by default
      abs_offset -= 1 if options[:remove_trigger_char]

      # Enumerate the AST looking for items that span the line/char we want.
      # Once we have all valid items, sort them by the smallest span.  Typically the smallest span
      # is the most specific object in the AST
      #
      # TODO: Should probably walk the AST and only look for the deepest child, but integer sorting
      #       is so much easier and faster.
      model_path_locator_struct = Struct.new(:model, :path, :locator)

      valid_models = []
      if result.model.respond_to? :eAllContents
        valid_models = result.model.eAllContents.select do |item|
          check_for_valid_item(item, abs_offset, options[:disallowed_classes])
        end

        valid_models.sort! { |a, b| a.length - b.length }
      else
        path = []
        result.model._pcore_all_contents(path) do |item|
          if check_for_valid_item(item, abs_offset, options[:disallowed_classes]) # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
            valid_models.push(model_path_locator_struct.new(item, path.dup))
          end
        end

        valid_models.sort! { |a, b| a[:model].length - b[:model].length }
      end
      # nil means the root of the document
      return nil if valid_models.empty?
      response = valid_models[0]

      if response.respond_to? :eAllContents # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
        response = model_path_locator_struct.new(response, construct_path(response))
      end

      response.locator = result.model.locator
      response
    end

    def self.construct_path(item)
      path = []
      item = item.eContainer
      while item.class != Puppet::Pops::Model::Program
        path.unshift item
        item = item.eContainer
      end

      path
    end

    def self.check_for_valid_item(item, abs_offset, disallowed_classes)
      item.respond_to?(:offset) && !item.offset.nil? && !item.length.nil? && abs_offset >= item.offset && abs_offset <= item.offset + item.length && !disallowed_classes.include?(item.class)
    end

    # This method is only required during development or debugging.  Visualising the AST tree can be difficult
    # so this method just prints it to the console.
    # def self.recurse_showast(item, abs_offset, disallowed_classes, depth = 0)
    #   output = "  " * depth
    #   output += check_for_valid_item(item, abs_offset, disallowed_classes) ? 'X ' : '  '
    #   output += "#{item.class.to_s} (#{item.object_id})"
    #   if item.respond_to?(:offset)
    #     output += " (Off-#{item.offset}:#{item.offset + item.length} Pos-#{item.line}:#{item.pos} Len-#{item.length}) ~#{item.locator.extract_text(item.offset, item.length)}~"
    #   end
    #   puts output
    #   item._pcore_contents do |child|
    #     recurse_showast(child, abs_offset, disallowed_classes, depth + 1)
    #   end
    # end
  end
end
