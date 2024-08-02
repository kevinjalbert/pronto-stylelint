# frozen_string_literal: true

require 'pronto'

module Pronto
  class Stylelint < Runner
    class Config
      EXECUTABLE_DEFAULT = 'stylelint'
      FILES_TO_LINT_DEFAULT = /\.(c|sc|sa|le)ss$/.freeze

      def stylelint_executable
        stylelint_config['stylelint_executable'] || EXECUTABLE_DEFAULT
      end

      def cli_options
        "#{stylelint_config['cli_options']} -f json".strip
      end

      def files_to_lint
        config_files_to_lint || FILES_TO_LINT_DEFAULT
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
