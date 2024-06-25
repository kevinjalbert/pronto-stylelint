# frozen_string_literal: true

RSpec.shared_context 'repo' do
  around(:example) do |example|
    create_repository
    Dir.chdir(repository_dir) do
      example.run
    end
    delete_repository
  end
end
