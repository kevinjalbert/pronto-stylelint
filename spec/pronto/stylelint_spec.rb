require 'spec_helper'

module Pronto
  describe Stylelint do
    let(:stylelint) { Stylelint.new(patches) }
    let(:patches) { [] }

    describe '#run' do
      subject(:run) { stylelint.run }

      context 'patches are nil' do
        let(:patches) { nil }

        it 'returns an empty array' do
          expect(run).to eql([])
        end
      end

      context 'no patches' do
        let(:patches) { [] }

        it 'returns an empty array' do
          expect(run).to eql([])
        end
      end

      context 'with patch data' do
        before(:each) do
          create_repository

          stylelint_config = <<~HEREDOC
            {
              "rules": {
                "color-named": "never",
                "unit-whitelist": ["em"]
              }
            }
          HEREDOC

          content = <<~HEREDOC
            .thing {
              font-size: 10em;
            }
          HEREDOC

          add_to_index('.stylelintrc.json', stylelint_config)
          add_to_index('style.css', content)

          create_commit
        end

        after(:each) { delete_repository }

        let(:patches) { Pronto::Git::Repository.new(repo.path).diff("master") }

        context "with warnings" do
          before(:each) do
            create_branch("staging", checkout: true)

            updated_content = <<~HEREDOC
              .thing {
                font-size:  10px;
              }

              a { color: pink;}
            HEREDOC

            add_to_index('style.css', updated_content)

            create_commit
          end

          it 'returns correct number of warnings' do
            expect(run.count).to eql(2)
          end

          it "has correct first message" do
            expect(run.first.msg).to eql('Unexpected named color "pink" (color-named)')
          end
        end

        context "no file matches" do
          before(:each) do
            create_branch("staging", checkout: true)

            add_to_index('random.js', 'alert("Hello World!")');

            create_commit
          end

          it 'returns no warnings' do
            expect(run.count).to eql(0)
          end
        end

        context "with custom stylelint_executable" do
          before(:each) do
            create_branch("staging", checkout: true)

            updated_content = <<~HEREDOC
              .thing {
                font-size:  10px;
              }

              a { color: pink;}
            HEREDOC

            add_to_index('style.css', updated_content)
            add_to_index('.pronto_stylelint.yml', "stylelint_executable: './custom_stylelint'")
            add_to_index('custom_stylelint', "printf 'custom stylelint called'")

            create_commit
          end

          it 'calls the custom stylelint stylelint_executable' do
            expect { run }.to raise_error(JSON::ParserError, /custom stylelint called/)
          end
        end
      end
    end

    describe '#files_to_lint' do
      subject(:files_to_lint) { stylelint.files_to_lint }

      it 'matches .css by default' do
        expect(files_to_lint).to match('my_css.css')
      end

      it 'matches .less by default' do
        expect(files_to_lint).to match('my_less.less')
      end

      it 'matches .scss by default' do
        expect(files_to_lint).to match('my_scss.scss')
      end

      it 'matches .sass by default' do
        expect(files_to_lint).to match('my_sass.sass')
      end
    end

    describe '#stylelint_executable' do
      subject(:stylelint_executable) { stylelint.stylelint_executable }

      it 'is `stylelint` by default' do
        expect(stylelint_executable).to eql('stylelint')
      end
    end
  end
end
