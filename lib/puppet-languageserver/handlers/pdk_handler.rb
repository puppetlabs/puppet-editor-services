# frozen_string_literal: true

require 'pdk'

module PuppetLanguageServer
  module Handlers
    module PdkHandler
      def self.new_class(name, target_dir)
        raise StandardError, "'#{name}' is not a valid class name" unless PDK::CLI::Util::OptionValidator.valid_defined_type_name?(name)

        PDK::Generate::PuppetClass.new(target_dir, name, {}).run
        [
          File.join(target_dir, "manifests/#{name}.pp"),
          File.join(target_dir, "spec/classes/#{name}_spec.rb")
        ]
      end

      def self.new_defined_type(name, target_dir)
        raise StandardError, "'#{name}' is not a valid defined type name" unless PDK::CLI::Util::OptionValidator.valid_defined_type_name?(name)

        PDK::Generate::DefinedType.new(target_dir, name, {}).run
        [
          File.join(target_dir, "manifests/#{name}.pp"),
          File.join(target_dir, "spec/defines/#{name}_spec.rb")
        ]
      end

      def self.new_task(name, target_dir)
        raise StandardError, "'#{name}' is not a valid task name" unless PDK::CLI::Util::OptionValidator.valid_task_name?(name)

        PDK::Generate::Task.new(target_dir, name, {}).run
        [
          File.join(target_dir, "tasks/#{name}.sh"),
          File.join(target_dir, "tasks/#{name}.json")
        ]
      end
    end
  end
end
