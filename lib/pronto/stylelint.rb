require 'pronto'
require 'shellwords'
require 'open3'

module Pronto
  class Stylelint < Runner
    CONFIG_FILE = '.pronto_stylelint.yml'.freeze
    CONFIG_KEYS = %w(stylelint_executable files_to_lint cli_options).freeze

    attr_writer :stylelint_executable, :cli_options

    def initialize(patches, commit = nil)
      super(patches, commit)
      read_config
    end

    def stylelint_executable
      @stylelint_executable || 'stylelint'.freeze
    end

    def cli_options
      "#{@cli_options} -f json".strip
    end

    def files_to_lint
      @files_to_lint || /\.(c|sc|sa|le)ss$/.freeze
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
        send("#{config_key}=", config[config_key])
      end
    end

    def run
      return [] if !@patches || @patches.count.zero?

      @patches
        .select { |patch| patch.additions > 0 }
        .select { |patch| style_file?(patch.new_file_full_path) }
        .map { |patch| inspect(patch) }
        .flatten.compact
    end

    private

    def git_repo_path
      @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd)).workdir
    end

    def inspect(patch)
      offences = run_stylelint(patch)
      clean_up_stylelint_output(offences)
        .map do |offence|
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

    def run_stylelint(patch)
      Dir.chdir(git_repo_path) do
        escaped_file_path = Shellwords.escape(patch.new_file_full_path.to_s)
        Open3.popen3("#{stylelint_executable} #{escaped_file_path} #{cli_options}") do |_stdin, stdout, stderr, thread|
          status = thread.value
          json = stdout.read
          if status.to_i == 0 && json.length == 0
            []
          else
            json = stderr.read if json.length == 0
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
        .select { |offence| offence['warnings'].size > 0 }
        .map { |offence| offence['warnings'] }
        .flatten.select { |offence| offence['line'] }
    end
  end
end
