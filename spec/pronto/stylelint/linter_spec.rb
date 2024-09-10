# frozen_string_literal: true

require 'spec_helper'

module Pronto
  class Stylelint
    describe Linter do
      let(:linter) { described_class.new(patch, Config.new) }

      describe '#run' do
        subject(:run) { linter.run }

        include_context 'repo'
        let(:patch) { Pronto::Git::Repository.new(repository_dir).diff('main').first }

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

            it { expect(run.count).to eql(1) }
            it { expect(run.first).to be_a(Hash) }
            it { expect(run.first['errored']).to eql(true) }
            it { expect(run.first['warnings'].size).to eql(2) }
            it { expect(run.first['warnings'].first['severity']).to eql('error') }
            it {
              expect(run.first['warnings'].first['text']).to eql(
                'Unexpected named color "pink" (color-named)'
              )
            }
            it { expect(run.first['warnings'].last['severity']).to eql('error') }
            it {
              expect(run.first['warnings'].last['text']).to eql(
                'Unexpected unknown unit "pxem" (unit-no-unknown)'
              )
            }
          end

          context 'with custom stylelint_executable' do
            before do
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
end
