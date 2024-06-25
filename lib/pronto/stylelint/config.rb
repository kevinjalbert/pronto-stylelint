# frozen_string_literal: true

require 'pronto'

module Pronto
  class Stylelint < Runner
    class Config
      CONFIG_FILE = '.pronto_stylelint.yml'
      CONFIG_KEYS = %w[stylelint_executable files_to_lint cli_options].freeze
      DEPRECATED_CONFIG =
        "Pronto::Stylelint: Using %<config_key>s from #{CONFIG_FILE} is deprecated. " \
        'Use .pronto.yml instead.'

      attr_writer :stylelint_executable, :cli_options

      def initialize
        read_config
      end

      def stylelint_executable
        stylelint_config['stylelint_executable'] || @stylelint_executable || 'stylelint'
      end

      def cli_options
        "#{stylelint_config['cli_options'] || @cli_options} -f json".strip
      end

      def files_to_lint
        config_files_to_lint || @files_to_lint || /\.(c|sc|sa|le)ss$/.freeze
      end

      def files_to_lint=(regexp)
        @files_to_lint = regexp.is_a?(Regexp) ? regexp : Regexp.new(regexp)
      end

      def read_config
        config_file = File.join(git_repo_path, CONFIG_FILE)
        return unless File.exist?(config_file)

        config = YAML.load_file(config_file)

        CONFIG_KEYS.each do |config_key|
          next unless config[config_key]

          warn format(DEPRECATED_CONFIG, config_key: config_key)
          send("#{config_key}=", config[config_key])
        end
      end

      def git_repo_path
        @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd)).workdir
      end

      private

      def config_files_to_lint
        return unless stylelint_config['files_to_lint']

        if stylelint_config['files_to_lint'].is_a?(Regexp)
          stylelint_config['files_to_lint']
        else
          Regexp.new(stylelint_config['files_to_lint'])
        end
      end

      def stylelint_config
        @stylelint_config ||= Pronto::ConfigFile.new.to_h['stylelint'] || {}
      end
    end
  end
end
