# frozen_string_literal: true

require 'pronto'
require 'shellwords'
require 'open3'
require 'pronto/stylelint/config'

module Pronto
  class Stylelint < Runner
    extend Forwardable

    CONFIG_FILE = '.pronto_stylelint.yml'
    CONFIG_KEYS = %w[stylelint_executable files_to_lint cli_options].freeze
    DEPRECATED_CONFIG =
      "Pronto::Stylelint: Using %<config_key>s from #{CONFIG_FILE} is deprecated. " \
      'Use .pronto.yml instead.'

    def_delegators(
      :stylelint_config,
      :stylelint_executable,
      :cli_options,
      :files_to_lint,
      :git_repo_path
    )
    private :stylelint_executable, :cli_options, :files_to_lint, :git_repo_path

    def initialize(patches, commit = nil)
      super
    end

    def run
      return [] if !@patches || @patches.count.zero?

      @patches
        .select { |patch| patch.additions.positive? && style_file?(patch.new_file_full_path) }
        .flat_map { |patch| inspect(patch) }
        .compact
    end

    private

    def cli_command(escaped_file_path)
      "#{stylelint_executable} #{escaped_file_path} #{cli_options}"
    end

    def inspect(patch)
      clean_up_stylelint_output(run_stylelint(patch)).flat_map do |offence|
        patch
          .added_lines
          .select { |line| line.new_lineno == offence['line'] }
          .map { |line| new_message(offence, line) }
      end
    end

    def new_message(offence, line)
      path = line.patch.delta.new_file[:path]
      level = :warning

      Message.new(path, line, level, offence['text'], nil, self.class)
    end

    def stylelint_config
      @stylelint_config ||= Pronto::Stylelint::Config.new
    end

    def style_file?(path)
      files_to_lint =~ path.to_s
    end

    def run_stylelint(patch)
      Dir.chdir(git_repo_path) do
        escaped_file_path = Shellwords.escape(patch.new_file_full_path.to_s)
        Open3.popen3(cli_command(escaped_file_path)) do |_stdin, stdout, stderr, thread|
          status = thread.value
          json = stdout.read
          if status.to_i.zero? && json.empty?
            []
          else
            json = stderr.read if json.empty?
            JSON.parse(json)
          end
        end
      end
    end

    def clean_up_stylelint_output(output)
      # 1. Filter out offences without a warning or error
      # 2. Get the messages for that file
      # 3. Ignore errors without a line number for now
      output
        .select { |offence| offence['warnings'].size.positive? }
        .flat_map { |offence| offence['warnings'] }
        .select { |offence| offence['line'] }
    end
  end
end
