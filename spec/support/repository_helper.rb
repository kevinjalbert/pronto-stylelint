module RepositoryHelper
  module_function

  attr_reader :repo, :tmp_git_dir

  def create_repository
    @tmp_git_dir = Dir.mktmpdir
    @repo = Rugged::Repository.init_at(@tmp_git_dir)
  end

  def delete_repository
    FileUtils.rm_r(tmp_git_dir)
  end

  def repository_dir
    File.realpath(tmp_git_dir) + '/'
  end

  def current_branch_name
    repo.head.name.sub(/^refs\/heads\//, '')
  end

  def add_to_index(file_name, blob_content)
    object_id = repo.write(blob_content, :blob)
    repo.index.add(path: file_name, oid: object_id, mode: 0100755)
    repo.index.write
  end

  def create_commit
    author = { email: 'john.doe@example.com', name: 'John Doe', time: Time.now }
    tree = repo.index.write_tree(repo)

    Rugged::Commit.create(repo,
                          author: author,
                          message: 'commit message',
                          committer: author,
                          parents: repo.empty? ? [] : [repo.head.target].compact,
                          tree: tree,
                          update_ref: 'HEAD')

    repo.checkout(current_branch_name, strategy: [:force])
  end

  def create_branch(branch_name, checkout: false)
    repo.create_branch(branch_name)
    checkout_branch(branch_name) if checkout
  end

  def checkout_branch(branch_name)
    repo.checkout(branch_name, strategy: [:force])
  end
end
