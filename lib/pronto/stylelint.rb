# frozen_string_literal: true

require 'pronto'
require 'shellwords'
require 'open3'
require 'pronto/stylelint/config'
require 'pronto/stylelint/linter'

module Pronto
  class Stylelint < Runner
    extend Forwardable

    attr_reader :stylelint_config

    def_delegators(
      :stylelint_config,
      :files_to_lint
    )
    private :files_to_lint

    def initialize(patches, commit = nil)
      super

      @stylelint_config ||= Pronto::Stylelint::Config.new
    end

    def run
      return [] if !@patches || @patches.count.zero?

      @patches
        .select { |patch| patch.additions.positive? && style_file?(patch.new_file_full_path) }
        .flat_map { |patch| inspect(patch) }
        .compact
    end

    private

    def inspect(patch)
      clean_up_stylelint_output(Linter.new(patch, stylelint_config).run).flat_map do |offence|
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

    def style_file?(path)
      files_to_lint =~ path.to_s
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
