# frozen_string_literal: true

require 'pronto'
require 'shellwords'
require 'open3'

module Pronto
  class Stylelint < Runner
    class Linter
      extend Forwardable

      attr_reader :stylelint_config

      def_delegators(
        :stylelint_config,
        :stylelint_executable,
        :cli_options,
        :git_repo_path
      )

      private :stylelint_executable, :cli_options, :git_repo_path

      STYLELINT_FAILURE = 'Stylelint failed to run'
      STATUS_CODES = {
        0 => :success,
        1 => :fatal_error,
        2 => :lint_problem,
        64 => :invalid_cli_usage,
        78 => :invalid_configuration_file
      }.freeze

      def initialize(patch, stylelint_config)
        @patch = patch
        @stylelint_config = stylelint_config
        @stylint_major_version = nil
      end

      def run
        Dir.chdir(git_repo_path) do
          Open3.popen3(cli_command) do |_stdin, stdout, stderr, thread|
            JSON.parse(
              case thread_status(thread)
              when :success, :lint_problem
                out = stdout.read
                out.empty? ? stderr.read : out
              else
                puts "#{STYLELINT_FAILURE} - #{thread_status(thread)}:\n#{stderr.read}"
                '[]'
              end
            )
          end
        end
      end

      private

      def cli_command
        "#{stylelint_executable} #{escaped_file_path} #{cli_options}"
      end

      def escaped_file_path
        Shellwords.escape(@patch.new_file_full_path.to_s)
      end

      # Status codes:
      # https://stylelint.io/user-guide/cli/#exit-codes
      def thread_status(thread)
        STATUS_CODES[thread.value.exitstatus] || :unknown
      end
    end
  end
end
