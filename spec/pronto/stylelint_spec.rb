# frozen_string_literal: true

require 'spec_helper'

module Pronto
  describe Stylelint do
    let(:stylelint) { Stylelint.new(patches) }
    let(:patches) { [] }

    describe '#run' do
      subject(:run) { stylelint.run }

      include_context 'repo'
      let(:patches) { Pronto::Git::Repository.new(repository_dir).diff('main') }

      context 'patches are nil' do
        let(:patches) { nil }

        it { expect(run).to eql([]) }
      end

      context 'no patches' do
        let(:patches) { [] }

        it { expect(run).to eql([]) }
      end

      context 'with patch data' do
        before do
          stylelint_config = <<-HEREDOC
            {
              "rules": {
                "color-named": "never",
                "unit-no-unknown": true
              }
            }
          HEREDOC

          content = <<-HEREDOC
            .thing {
              font-size: 10pxem;
            }
          HEREDOC

          add_to_index('.stylelintrc.json', stylelint_config)
          add_to_index('style.css', content)

          create_commit
        end

        context 'with warnings' do
          before do
            create_branch('staging', checkout: true)

            add_to_index('style.css', <<-HEREDOC)
              .thing {
                font-size:  10pxem;
              }

              a { color: pink;}
            HEREDOC

            add_to_index('style.scss', <<-HEREDOC)
              .thing {
                font-size:  10pxem;

                a { color: pink;}
              }
            HEREDOC

            create_commit
          end

          it { expect(run.count).to eql(4) }
          it { expect(run.first.msg).to eql('Unexpected named color "pink" (color-named)') }

          context 'with files to lint config that matches only .css' do
            before do
              add_to_index('.pronto.yml', "stylelint:\n  files_to_lint: '\\.css$'")
              create_commit
            end

            it { expect(run.count).to eql(2) }
          end

          context 'with files to lint config that never matches' do
            before do
              add_to_index('.pronto.yml', "stylelint:\n  files_to_lint: 'will never match'")
              create_commit
            end

            it { expect(run.count).to eql(0) }
          end
        end

        context 'no file matches' do
          before do
            create_branch('staging', checkout: true)

            add_to_index('random.js', 'alert("Hello World!")')

            create_commit
          end

          it { expect(run.count).to eql(0) }
        end

        context 'with custom stylelint_executable' do
          before(:each) do
            create_branch('staging', checkout: true)

            updated_content = <<-HEREDOC
              .thing {
                font-size:  10px;
              }

              a { color: pink;}
            HEREDOC

            add_to_index('style.css', updated_content)
            add_to_index('.pronto.yml', "stylelint:\n  stylelint_executable: './custom_stylelint'")
            add_to_index('custom_stylelint', "printf 'custom stylelint called'")

            create_commit
          end

          it { expect { run }.to raise_error(JSON::ParserError, /custom stylelint called/) }
        end
      end
    end
  end
end
