# frozen_string_literal: true

require 'spec_helper'

module Pronto
  class Stylelint
    describe Config do
      let(:config) { Config.new }
      let(:patches) { [] }

      describe '#cli_options' do
        subject(:cli_options) { config.cli_options }

        include_context 'repo'

        it { expect(cli_options).to eq('-f json') }

        context 'with custom cli_options' do
          before do
            add_to_index('.pronto_stylelint.yml', "cli_options: '--test option'")
            create_commit
          end

          it { expect(cli_options).to eq('--test option -f json') }
        end

        context 'with custom cli_options via the .pronto.yml' do
          before do
            add_to_index('.pronto.yml', "stylelint:\n  cli_options: '--test option'")
            create_commit
          end

          it { expect(cli_options).to eq('--test option -f json') }
        end
      end

      describe '#files_to_lint' do
        subject(:files_to_lint) { config.files_to_lint }

        it { expect(files_to_lint).to match('my_css.css') }
        it { expect(files_to_lint).to match('my_less.less') }
        it { expect(files_to_lint).to match('my_scss.scss') }
        it { expect(files_to_lint).to match('my_sass.sass') }

        context 'with custom files_to_lint' do
          include_context 'repo'

          before do
            add_to_index('.pronto_stylelint.yml', "files_to_lint: '\\.css$'")
            create_commit
          end

          it { expect(files_to_lint).to match('my_css.css') }
          it { expect(files_to_lint).not_to match('my_less.less') }
          it { expect(files_to_lint).not_to match('my_scss.scss') }
          it { expect(files_to_lint).not_to match('my_sass.sass') }
        end

        context 'with custom files_to_lint via the .pronto.yml' do
          include_context 'repo'

          before do
            add_to_index('.pronto.yml', "stylelint:\n  files_to_lint: '\\.css$'")
            create_commit
          end

          it { expect(files_to_lint).to match('my_css.css') }
          it { expect(files_to_lint).not_to match('my_less.less') }
          it { expect(files_to_lint).not_to match('my_scss.scss') }
          it { expect(files_to_lint).not_to match('my_sass.sass') }
        end
      end

      describe '#stylelint_executable' do
        subject(:stylelint_executable) { config.stylelint_executable }

        it { expect(stylelint_executable).to eql('stylelint') }

        context 'with custom stylelint_executable' do
          include_context 'repo'

          before do
            add_to_index('.pronto_stylelint.yml', "stylelint_executable: 'custom_stylelint'")
            create_commit
          end

          it { expect(stylelint_executable).to eql('custom_stylelint') }
        end

        context 'with custom stylelint_executable via the .pronto.yml' do
          include_context 'repo'

          before do
            add_to_index('.pronto.yml', "stylelint:\n  stylelint_executable: 'custom_stylelint'")
            create_commit
          end

          it { expect(stylelint_executable).to eql('custom_stylelint') }
        end
      end
    end
  end
end
