class Repository
  attr_reader :wd, :options, :url, :branch, :deploy_to

  def initialize(wd, options)
    @wd = wd
    @options = options
    @url = options['url']
    @branch = options['branch']
    @deploy_to = options['deploy_to']
  end

  def debugging?
    wd.debugging?
  end

  def clone
    [
      "cd #{parent_path}",
      "if [ -e #{deploy_to} ]; then echo 'Repository already cloned to [#{deploy_to}].  Skipping.'; " +
            "else git clone #{url} #{tail_path} && #{safe_branch_checkout}; fi",
    ]
  end

  def ensure_parent_path_is_present
    [ "mkdir -p #{parent_path}" ]
  end

  def refresh_checkout
    [
     "cd #{deploy_to}",
     "git fetch origin +refs/heads/#{branch}:refs/remotes/origin/#{branch} #{'&>/dev/null' unless debugging?}",
     "git checkout #{branch} #{'&>/dev/null' unless debugging?}",
     "git reset --hard origin/#{branch} #{'&>/dev/null' unless debugging?}"
    ]
  end

  def parent_path
    File.split(deploy_to).first
  end

  def tail_path
    File.split(deploy_to).last
  end

  def safe_branch_checkout
    %Q(cd #{deploy_to} && git checkout -b #{branch} origin/#{branch} || git checkout #{branch} origin/#{branch} || git checkout #{branch})
  end
end
