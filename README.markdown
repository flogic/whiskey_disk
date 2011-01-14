## Whiskey Disk -- embarrassingly fast deployments. ##


A very opinionated deployment tool, designed to be as fast as technologically possible.  (For more background, read the [WHY.txt](http://github.com/flogic/whiskey_disk/raw/master/WHY.txt) file)  Should work with any project which is git hosted, not just Ruby / Ruby on Rails projects.  Allows for local deploys as well as remote.

Right-arrow through a short whiskey_disk presentation at [http://wd2010.rickbradley.com/](http://wd2010.rickbradley.com) (slide source available [here](http://github.com/rick/whiskey_disk_presentation).), covering the 0.2.*-era functionality.

You can also right-arrow through a shorter but more up-to-date whiskey_disk "lightning talk" presentation 
(from the 2010 Ruby Hoedown) at [http://wdlightning.rickbradley.com/](http://wdlightning.rickbradley.com) (slide source available [here](http://github.com/rick/whiskey_disk_presentation/tree/lightning).), covering the 0.4.*-era functionality.

### tl;dr ###

First:

    % gem install whiskey_disk


Then make a deploy.yml file (in config/ if you're doing a Rails project):

    staging:
      domain: "deployment_user@staging.mydomain.com"
      deploy_to: "/path/to/where/i/deploy/staging.mydomain.com"
      repository: "https://github.com/username/project.git"
      branch: "staging"
      rake_env:
        RAILS_ENV: 'production'	    

then:

    % wd setup --to=staging

then:

    % wd deploy --to=staging


### Selling points ###

  - If you share the same opinions as we do there's almost no code involved, almost no
    dependencies, and it uses stock *nix tools (ssh, bash, rsync) to get
everything done.

  - Written completely spec-first for 100% coverage.  We even did that for the
    rake tasks, the init.rb and the plugin install.rb (if you swing that way).

  - 1 ssh connection per run -- so everything needed to do a full setup
    is done in one shot.  Everything needed to do a full deployment is done in
one shot.  (Having 8 minute deploys failing because I was on CDMA wireless on a
train in India where the connection won't stay up for more than 2-3 minutes is
not where I want to be any more.)

  - Deployment configuration is specified as YAML data, not as code.
    Operations to perform after setup or deployment are specified as rake
tasks.

  - You can do *local* deployments, by this I mean you can use whiskey\_disk to
    deploy fully running instances of your application to the same machine
you're developing on.  This turns out to be surprisingly handy (well, I was
surprised).  *NOTE*:  be sure to set your deploy_to to a place other than the
current local checkout.

  - You can do multi-project deployments, specifying deployment data in a single
    deploy.yml config file, or keep an entire directory of project deployment config files.

  - You can separate per-deployment application configuration information (e.g., passwords, 
    database configs, hoptoad/AWS/email config data, etc.) in separate repositories from 
    the application, and whiskey\_disk will merge the correct data onto the deployed 
    application at deployment time.  You can even share sets of configuration files among
    deployment targets that behave alike.

  - You can have per-developer configurations for targets (especially
    useful for "local" or "development" targets).  Use .gitignore, or
    specify a config_branch and everyone can have their own local setup that just
    works.

  - There's no before\_after\_before_after hooks.  You can use a well-defined rake hook and/or a 
    bash script to run additional tasks.
 
  - You can enable "staleness checks" so that deployments only happen if
    either the main repo, or the config repo (if you're using one) has
    changes that are newer than what is currently deployed.

  - Put whiskey\_disk in a cron, with staleness checks enabled, and you can
    do hands-free automated deployments whenever code is pushed to your
    deployment branch of choice!

  - You can deploy to multiple remote targets at once.  Currently this is limited
    to one-after-the-other synchronous deployments, but we're thinking about 
    doing them in parallel once we're happy with the stability of this (new)
    feature.

  - Assign hosts to roles (e.g., "web", "db", "app") and vary the shell or rake 
    post-setup/post-deploy actions you run based on those roles.

### Assumptions ###

 - your project is managed via git
 - you are deploying over ssh, or deploying locally and have a bash-compatible shell
 - you are comfortable defining (optional) post-setup and post-deployment actions with rake
 - you have an optional second git repository for per-application/per-target configuration files
 - you have an optional Rakefile in the top directory of your project's checkout

### Dependencies ###

On the server from which the whiskey_disk process will be kicked off:  

 - ruby
 - rake
 - whiskey\_disk
 - ssh (if doing a remote deployment).  

On the deployment target server (which may be the same as the first server):  

 - a bash-compatible shell
 - rsync (only if using a configuration repository)
 - ruby, rake, whiskey\_disk (only if running post\_setup or post\_deploy hooks)

If you're running on OS X or Linux you probably have all of these installed already.  Note that the deployment target system doesn't even have to have ruby installed unless post\_* rake hooks are being run.

### Installation ###

As a gem:

    % gem install whiskey_disk

As a rails plugin:

    % script/plugin install git://github.com/flogic/whiskey_disk.git

### Configuration ###

 - look in the examples/ directory for sample configuration files
 - main configuration is in &lt;app_root&gt;/config/deploy.yml
 - config files are YAML, with a section for each target.

Known config file settings (if you're familiar with capistrano and vlad these should seem eerily familiar):
 
    domain:              host or list of hosts on which to deploy (these are ssh connect strings)
                         can also optionally include role information for each host
    deploy_to:           path to which to deploy main application
    repository:          git repo path for main application
    branch:              git branch to deploy from main application git repo (default: master)
    deploy_config_to:    where to deploy the configuration repository
    config_repository:   git repository for configuration files
    config_branch:       git branch to deploy from configuration git repo (default: master)
    config_target:       configuration repository target path to use
    project:             project name (used to compute path in configuration checkout)
    post_deploy_script:  path to a shell script to run after deployment
    post_setup_script:   path to a shell script to run after setup
    rake_env:            hash of environment variables to set when running post_setup and post_deploy rake tasks


A simple config/deploy.yml might look like:
  
    qa:
      domain: "ogc@qa.ogtastic.com"
      deploy_to: "/var/www/www.ogtastic.com"
      repository: "git@ogtastic.com:www.ogtastic.com.git"
      branch: "stable"
      rake_env:
        RAILS_ENV: 'production'

 - defining a deploy:&lt;target&gt;:post_setup rake task (e.g., in lib/tasks/
   or in your project's Rakefile) will cause that task to be run at the end
of deploy:setup

 - defining a deploy:&lt;target&gt;:post_deploy rake task (e.g., in
   lib/tasks/ or in your project's Rakefile) will cause that task to be run
at the end of deploy:now


For deploying to multiple hosts, the config/deploy.yml might look like:

    qa:
      domain:
      - "ogc@qa1.ogtastic.com"
      - "ogc@qa2.ogtastic.com""
      deploy_to: "/var/www/www.ogtastic.com"
      repository: "git@ogtastic.com:www.ogtastic.com.git"
      branch: "stable"
      rake_env:
        RAILS_ENV: 'production'


### Specifying domains, with or without roles ###

There are a number of ways to specify domains (the ssh connection strings denoting the hosts
where your code will be deployed).  Here are just a few examples:

Just a single domain:

    staging:
      domain: "foo@staging.example.com"

Just a single domain, but specified as a one-item list:

    qa:
      domain: 
      - "foo@qa.example.com"

A list of multiple domains:

    production:
      domain:
      - "foo@appserver1.example.com"
      - "foo@appserver2.example.com"
      - "foo@www.example.com"

Using the "name" label for the domain names (if using roles, as described below, the "name" label is required,
otherwise it's optional and superfluous):

    ci:
      domain:
      - name: "build@ci.example.com"


It's also possible to assign various "roles" to the domains to which you deploy.  Some common usages would be
"www", which might need a post\_deploy task which notifies some web server software (apache, nginx, passenger, 
unicorn, etc.) that it should refresh the contents being served; or perhaps "db", which might need some set of
post-deployment database migrations run (and which shouldn't be run from multiple servers).

The role names are simply strings and you can create whichever roles you wish.  See the section below entitled
"Taking actions based on roles" to see how to use roles to control actions when setting up or deploying to a
target.

Roles are described in the domain: section of the configuration file.  There are, of course, a few different
valid ways to specify roles.  Note that the domain name must now be labeled when roles are being specified
for the domain.

A single role for a domain can be specified inline:

    production:
      domain:
      - name: "foo@appserver1.example.com"
        roles: "web"

While multiple roles for a domain must be specified as a list:

    production:
      domain:
      - name: "foo@appserver1.example.com"
        roles: 
        - "web"
        - "app"
        - "db"

But domains with roles can be specified alongside simple domains as well:

    production:
      domain:
      - name: "bar@demo.example.com"
      - "user@otherhost.domain.com"
      - name: "foo@appserver1.example.com"
        roles: 
        - "web"
        - "app"
        - "db"


All that said, it's often simpler to refrain from carving up hosts into roles.  But who's going to listen to reason?



### post\_deploy\_script and post\_setup\_script ###

Whiskey\_disk provides rake task hooks (deploy:post\_setup and deploy:post\_deploy) to allow running custom
code after setup or deployment.  There are situations where it is desirable to run some commands prior to 
running those rake tasks (e.g., if using bundler and needing to do a 'bundle install' before running rake).
It may also be the case that the target system doesn't have rake (and/or ruby) installed, but some post-setup
or post-deploy operations need to happen.  For these reasons, whiskey\_disk allows specifying a (bash-compatible)
shell script to run after setup and/or deployment via the post\_deploy\_script and post\_setup\_script settings
in the configuration file.  These scripts, when specified, are run immediately before running the deploy:post\_setup 
or deploy:post\_deploy rake tasks, if they are present.

The paths provided to post\_deploy\_script and post\_setup\_script can be either absolute or relative.  A path
starting with a '/' is an absolute path, and the script specified should be at that exact location on the 
target filesystem.  A path which does not start with a '/' is a relative path, and the script specified should
be located at the specified path under the deployed application path.  This implies that it's possible to 
manage post\_setup and post\_deploy scripts out of a configuration repository.

A config/deploy.yml using post\_deploy\_script and post\_setup\_script might look like this:
  
    production:
      domain: "ogc@www.ogtastic.com"
      deploy_to: "/var/www/www.ogtastic.com"
      repository: "git@ogtastic.com:www.ogtastic.com.git"
      branch: "stable"
      post_setup_script: "/home/ogc/horrible_place_for_this/prod-setup.sh"
      post_deploy_script: "bin/post-deploy.sh"
      rake_env:
        RAILS_ENV: 'production'

The post\_deploy\_script will be run from /var/www/www.ogtastic.com/bin/post-deploy.sh on the 
target system.


### Taking actions based on roles ###

#### When running rake tasks or other ruby scripts ####

Whiskey\_disk includes a helper library for use in rake tasks and other ruby scripts.  In that library you'll
find a ruby function 'role?' which returns true if you're currently being deployed to a domain with the given
role.  For example:

<code>
    
    require 'whiskey_disk/helpers'

    namespace :deploy do
      task :create_rails_directories do
        if role? :www
          puts "creating log/ and tmp/ directories"
          Dir.chdir(RAILS_ROOT)
          system("mkdir -p log tmp")
        end
      end        

      task :db_migrate_if_necessary do
				Rake::Task['db:migrate'] if role? :db
      end

      # whytf is this even necessary?  Come on.  This should be built into ts:restart.
      task :thinking_sphinx_restart => [:environment] do
        if role? :app
          Rake::Task['ts:stop'].invoke rescue nil
          Rake::Task['ts:index'].invoke
          Rake::Task['ts:start'].invoke
        end
      end
    
      task :bounce_passenger do
        if role? :www
          puts "restarting Passenger web server"
          Dir.chdir(RAILS_ROOT)
          system("touch tmp/restart.txt")    
        end
      end

      # etc...
    
      task :post_setup  => [ :create_rails_directories ]
      task :post_deploy => [ :db_migrate_if_necessary, :thinking_sphinx_restart, :bounce_passenger ]
    end
</code>


#### When working with the shell ####

Installing the whiskey\_disk gem also installs another binary, called wd_role.  It's job is really simple,
given a role, determine if we're currently in a deployment that matches that role.  If so, exit with a success
exit status, otherwise, exit with an error exit status.  This allows programs running in the shell to conditionally
execute code based on domain roles.  This is particularly applicable to post\_setup\_script and post\_deploy\_script
code.

Here's an off-the-cuff example of how one might use wd\_role.  We have the rockhands gem installed (obviously), and
are in an environment where the 'app' role is active but the 'web' role is not:


    $ wd_role web && rock || shocker
         .-.     
       .-.U|     
       |U| | .-. 
       | | |_|U| 
       | | | | | 
      /|     ` |
     | |       | 
     |         | 
      \        / 
      |       |  
      |       |  
                 
    $ wd_role app && rock || shocker
       .-.       
       |U|       
       | |   .-. 
       | |-._|U| 
       | | | | | 
      /|     ` | 
     | |       | 
     |         | 
              / 
      |       |  
      |       |  
    



### Running whiskey\_disk from the command-line ###
  
    % wd setup --to=<target>
    % wd setup --to=<project>:<target>
    % wd setup --to=foo:qa --path=/etc/whiskey_disk/deploy.yml
    % wd setup --to=foo:qa --path=https://github.com/username/project/raw/master/path/to/configs/deploy.yml
    
    % wd deploy --to=<target>
    % wd deploy --to=<project>:<target>
    % wd deploy --to=foo:qa --path=/etc/whiskey_disk/deploy.yml
    % wd deploy --to=foo:qa --path=https://github.com/username/project/raw/master/path/to/configs/deploy.yml


Note that the wd command (unlike rake, which requires a Rakefile in the current directory) can be run from anywhere, so you can deploy any project, working from any path, and can even specify where to find the deployment YAML configuration file.
  
The --path argument can take either a file or a directory.  When given a file it will use that file as the configuration file.  When given a directory it will look in that directory for deploy/&lt;project&gt;/&lt;target&gt;.yml, then deploy/&lt;project&gt;.yml, then deploy/&lt;target&gt;.yml, then &lt;target&gt;.yml, and finally, deploy.yml.

To make things even better, you can provide an URL as the --path argument and have a central location from which to pull deployment YAML data.  This means that you can centrally administer the definitive deployment information for the various projects and targets you manage.  This could be as simple as keeping them in a text file hosted on a web server, checking them into git and using github or gitweb to serve up the file contents on HEAD, or it could be a programmatically managed configuration management system returning dynamically-generated results.

All this means you can manage a large number of project deployments (local or remote) and have a single scripted deployment manager that keeps them up to date.  Configurations can live in a centralized location, and developers don't have to be actively involved in ensuring code gets shipped up to a server.  Win.


### A note about post\_{setup,deploy} Rake tasks

If you want actions to run on the deployment target after you do a whiskey\_disk setup or whiskey\_disk deploy, 
you will need to make sure that whiskey\_disk is available on the target system (either by gem installation,
as a rails plugin in the Rails application to be deployed, or as a vendored library in the application to be
deployed).  Whiskey\_disk provides the basic deploy:post\_setup and deploy:post\_deploy hooks which get called.
You can also define these tasks yourself if you want to eliminate the dependency on whiskey\_disk on the
deployment target system.


### Running via rake ###

In your Rakefile:

    require 'whiskey_disk/rake'

  Then, from the command-line:

    % rake deploy:setup to=<target>   (e.g., "qa", "staging", "production", etc.)
    % rake deploy:now   to=<target>

  or, specifying the project name:

    % rake deploy:setup to=<project>:<target>   (e.g., "foo:qa", "bar:production", etc.)
    % rake deploy:now   to=<project>:<target>

  enabling staleness checking (see below):

  % rake deploy:setup to=<project>:<target> check=yes
  % rake deploy:now   to=<project>:<target> check=yes

  maybe even specifying the path to the configuration file:

  % rake deploy:setup to=<project>:<target> path=/etc/deploy.yml
  % rake deploy:now   to=<project>:<target> path=/etc/deploy.yml

  how about specifying the configuration file via URL:

  % rake deploy:setup to=<project>:<target> path=https://github.com/username/project/raw/master/path/to/configs/deploy.yml
  % rake deploy:now   to=<project>:<target> path=https://github.com/username/project/raw/master/path/to/configs/deploy.yml


### Staleness checks ###

Enabling staleness checking will cause whiskey\_disk to check whether the deployed checkout of the repository
is out of date ("stale") with respect to the upstream version in git.  If there is a configuration repository
in use, whiskey\_disk will check the deployed checkout of the configuration repository for staleness as well.
If the checkouts are already up-to-date the deployment process will print an up-to-date message and stop rather
than proceeding with any of the deployment actions.  This makes it easy to simply run whiskey\_disk out of cron
so that it will automatically perform a deployment whenever changes are pushed to the upstream git repositories.

To turn on staleness checking, simply specify the '--check' flag when deploying (or the shorter '-c')

    wd deploy --check --to=foobar:production

If running whiskey\_disk purely via rake, you can also enable staleness checking.  This works by setting the 'check'
environment variable to the string 'true' or 'yes':

    % check='true' to='whiskey_disk:testing' rake deploy:now


### Configuration Repository ###

#### What's all this about a second repository for configuration stuff? ####

This is completely optional, but we really are digging this, so maybe 
you should try it.  Basically it goes like this...

We have a number of web applications that we manage.  Usually there's a
customer, there might be third-party developers, or the customer might have
access to the git repo, or their designer might, etc.  We also tend to run a
few instances of any given app, for any given customer.  So, we'll run a
"production" site, which is the public- facing, world-accessible main site.
We'll usually also run a "staging" site, which is roughly the same code, maybe
the same data, running on a different URL, which the customer can look at to
see if the functionality there is suitable for deploying out to production.  We
sometimes run a "development" site which is even less likely to be the same
code as production, etc., but gives visibility into what might end up in
production one day soon.

So we'll store the code for all of these versions of a site in the same git
repo, typically using a different remote branch for each target
("qa", "production", "staging", "development").

One thing that comes up pretty quickly is that there are various files
associated with the application which have more to do with configuration of a
running instance than they have to do with the application in general.  In the
rails world these files are probably in config, or config/initializers/.  Think
database connection information, search engine settings, exception notification
plugin data, email configuration, Amazon S3 credentials, e-commerce back-end
configuration, etc.

We don't want the production site using the same database as the
development site.  We don't want staging using (and re-indexing, re-starting,
etc.) production's search engine server.  We don't want any site other than
production to send account reset emails, or to push orders out to fulfillment,
etc.

For some reason, the answer to this with cap and/or vlad has been to have
recipes which reference various files up in a shared area on the server, do
copying or symlinking, etc.  Where did those files come from?  How did they get
there?  How are they managed over time?  If they got there via a configuration
tool, why (a) are they not in the right place, or (b) do we have to do work to
get them into the right place?

So, we decided that we'd change how we deal with the issue.  Instead of
moving files around or symlinking every time we deploy, we will manage the
configuration data just like we manage other files required by our projects --
with git.

So, each project we deploy is associated with a config repo in our git
repository.  Usually many projects are in the same repo, because we're the only
people to see the data and there's no confidentiality issue.  But, if a
customer has access to their git information then we'll make a separate config
repo for all that customers' projects.  (This is easier to manage than it
sounds if you're using gitosis, btw.)

Anyway, a config repo is just a git repo.  In it are directories for every
project whose configuration information is managed in that repo.  For example,
there's a "larry" directory in our main config repo, because we're deploying
the [larry project](http://github.com/flogic/larry) to manage our high-level
configuration data.

Note, if you set the 'project' setting in deploy.yml, that determines the
name of the top-level project directory whiskey\_disk will hunt for in your
config repo.  If you don't it uses the 'repository' setting (i.e., the git URL)
to try to guess what the project name might be.  So if the URL ends in
foo/bar.git, or foo:bar.git, or /bar, or :bar, whiskey\_disk is going to guess
"bar".  If it's all bitched up, just set 'project' manually in deploy.yml.

Inside the project directory is a directory named for each target we
might deploy to.  Frankly, we've been using "production", "staging",
"development", and "local" on just about everything.

Inside the target directory is a tree of files.  So, e.g., there's
config/, which has initializers/ and database.yml in it.

Long story short, load up whatever configuration files you're using into
the repo as described, and come deployment time exactly those files will be
overlaid on top of the most recent checkout of the project.  Snap.

    project-config/
      |
      +---larry/
            |
            +---production/
            |     |
            |     +---config/
            |           |
            |           +---initializers/
            |           |
            |           +---database.yml
            |
            +---staging/
            |     |
            |     |
            |     +---config/
            |           |
            |           ....
            |
            +---development/
            |     |
            |     +---config/
            |           |
            |           ....
            |
            +---local/
                  |
                  +---config/
                        |
                        ....


#### Sharing a set of configuration files among multiple targets ####

Developers on applications with many deployment targets can find that configuration repositories can become a burden to maintain, especially when a number of environments share essentially the same configurations.  For example, for an application where deployments for user acceptance testing, QA, staging, and feature branch demoing are all essentially the same (though differing from production configurations and developer configurations), it's probably easiest to store a configuration for development, a configuration for production, a configuration for staging and then use the staging configuration for all the other environments: user acceptance testing, QA, staging, demo1, demo2, etc.  Using the config\_target setting, a deploy.yml might look like this:


    production:
      domain: "www.ogtastic.com"
      deploy_to: "/var/www/www.ogtastic.com"
      repository: "git@ogtastic.com:www.ogtastic.com.git"
      branch: "production"
      config_repository: "git@ogtastic.com:ogc-production-config.git"
    development:
      deploy_to: '/var/www/devel.ogtastic.com'
      repository: "git@ogtastic.com:www.ogtastic.com.git"
      branch: "develop"
      config_repository: "git@ogtastic.com:ogc-config.git"
    staging:
      [...]
      config_repository: "git@ogtastic.com:ogc-config.git"
    uat:
      [....]
      config_repository: "git@ogtastic.com:ogc-config.git"
      config_target: "staging"
    qa:
      [....]
      config_repository: "git@ogtastic.com:ogc-config.git"
      config_target: "staging"


So here we have the 'staging', 'uat', and 'qa' deployment targets all sharing the 'staging' configuration repo information.  The non-production configuration repo can then look like:


    project-config/
      |
      +---ogtastic/
            |
            +---staging/
            |     |
            |     |
            |     +---config/
            |           |
            |           ....
            |
            +---development/
                  |
                  +---config/
                        |
                        ....


Notice that there are no separate trees for 'uat' and 'qa' targets.

### More Examples: ###

 - We are using whiskey\_disk to manage larry.  See [https://github.com/flogic/larry/blob/master/config/deploy-local.yml.example](https://github.com/flogic/larry/blob/master/config/deploy-local.yml.example) and [http://github.com/flogic/larry/blob/master/lib/tasks/deploy.rake](http://github.com/flogic/larry/blob/master/lib/tasks/deploy.rake)

 - Here is a sample of a lib/tasks/deploy.rake from a Rails application we deployed once upon a time:

<code>

    RAILS_ENV=ENV['RAILS_ENV'] if ENV['RAILS_ENV'] and '' != ENV['RAILS_ENV']
    Rake::Task['environment'].invoke
    
    require 'asset_cache_sweeper'

    namespace :deploy do
      task :create_rails_directories do
        puts "creating log/ and tmp/ directories"
        Dir.chdir(RAILS_ROOT)
        system("mkdir -p log tmp")
      end
    
      # note that the plpgsql language needs to be installed by the db admin at initial database creation :-/
      task :setup_postgres_for_thinking_sphinx => [ :environment ] do
        ThinkingSphinx::PostgreSQLAdapter.new(Product).setup
      end
    
      # whytf is this even necessary?  Come on.  This should be built into ts:restart.
      task :thinking_sphinx_restart => [:environment] do
        Rake::Task['ts:stop'].invoke rescue nil
        Rake::Task['ts:index'].invoke
        Rake::Task['ts:start'].invoke
      end
    
      task :bounce_passenger do
        puts "restarting Passenger web server"
        Dir.chdir(RAILS_ROOT)
        system("touch tmp/restart.txt")    
      end
    
      task :clear_asset_cache => [:environment] do
        STDERR.puts "Expiring cached Assets for domains [#{AssetCacheSweeper.domains.join(", ")}]"
        AssetCacheSweeper.expire
      end
    
      task :post_setup => [ :create_rails_directories, :setup_postgres_for_thinking_sphinx ]
      task :post_deploy => [ 'db:migrate', 'ts:config', :thinking_sphinx_restart, :bounce_passenger, :clear_asset_cache ]
    end
</code>

### Future Directions ###

Check out the [Pivotal Tracker project](https://www.pivotaltracker.com/projects/202125)
to see what we have in mind for the near future.

### Resources ###

 - [http://github.com/blog/470-deployment-script-spring-cleaning](http://github.com/blog/470-deployment-script-spring-cleaning)
 - [http://github.com/mislav/git-deploy](http://github.com/mislav/git-deploy)
 - [http://toroid.org/ams/git-website-howto](http://toroid.org/ams/git-website-howto)


### Contributors ###

 - Rick Bradley (rick@rickbradley.com, github:rick)
 - Jeremy Holland (jeremy@jeremypholland.com, github:therubyneck): feature/bugfix contributions
 - Kevin Barnes (@vinbarnes), Yossef Mendellsohn (cardioid) for design help and proofreading
 - Cristi Balan (evilchelu) for feedback and proofreading
