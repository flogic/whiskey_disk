## Whiskey Disk -- embarrassingly fast deployments. ##


A very opinionated deployment tool, designed to be as fast as technologically possible.  (For more background, read the [WHY.txt](http://github.com/flogic/whiskey_disk/raw/master/WHY.txt) file)  Should work with any project which is git hosted, not just Ruby / Ruby on Rails projects.  Allows for local deploys as well as remote.

Right-arrow through a short whiskey_disk presentation at [http://wd2010.rickbradley.com/](http://wd2010.rickbradley.com) (slide source available [here](http://github.com/rick/whiskey_disk_presentation).), covering the 0.2.*-era functionality.

### Selling points ###

  - If you share the same opinions as we do there's almost no code involved, almost no
    dependencies, and it uses stock *nix tools (ssh, bash, rsync) to get
everything done.

  - Written completely spec-first for 100% coverage.  We even did that for the
    rake tasks, the init.rb and the plugin install.rb (if you swing that way).

  - 1 ssh connection per run -- so everything needed to do a full setup
    is done in one shot.  Everything needed to do a full deployment is done in
one shot.  (Having 8 minute deploys failing because I was on CDMA wireless on a
train in india where the connection won't stay up for more than 2-3 minutes is
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

  - You can have per-developer configurations for targets (especially
    useful for "local" or "development" targets).  Use .gitignore, or
specify a config_branch and everyone can have their own local setup that just
works.

  - There's no before\_after\_before_after hooks.  You've got plenty of
    flexibility with just a handful of rake hook points to grab onto.
 
  - You can enable "staleness checks" so that deployments only happen if
    either the main repo, or the config repo (if you're using one) has
    changes that are newer than what is currently deployed.

  - Put whiskey\_disk in a cron, with staleness checks enabled, and you can
    do hands-free automated deployments whenever code is pushed to your
    deployment branch of choice!

#### Dependencies ####

rake, ssh, git, rsync on the deployment target server (affectionately referred to as the "g-node" by vinbarnes), bash-ish shell on deployment server.

#### Assumptions ####

 - you have a Rakefile in the top directory of your project's checkout
 - you are deploying over ssh
 - your project is managed via git
 - you are comfortable defining post-setup and post-deployment actions with rake
 - you have an optional second git repository for per-application/per-target configuration files

### Installation ###

As a gem:

    % gem install whiskey_disk

As a rails plugin:

    % script/plugin install git://github.com/flogic/whiskey_disk.git

### Configuration ###

 - look in the examples/ directory for sample configuration files
 - main configuration is in %lt;app_root&gt;/config/deploy.yml
 - config files are YAML, with a section for each target.

Known config file settings (if you're familiar with capistrano and vlad these should seem eerily familiar):
 
    domain:            host on which to deploy (this is an ssh connect string) 
    deploy_to:         path to which to deploy main application
    repository:        git repo path for main application
    branch:            git branch to deploy from main application git repo (default: master)
    deploy_config_to:  where to deploy the configuration repository
    config_repository: git repository for configuration files
    config_branch:     git branch to deploy from configuration git repo (default: master)
    project:           project name (used to compute path in configuration checkout)
    rake_env:          hash of environment variables to set when running post_setup and post_deploy rake tasks


A simple config/deploy.yml might look like:
  
    qa:
      domain: "ogc@www.ogtastic.com"
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



### Running via rake ###

In your Rakefile:

    require 'whiskey_disk/rake'

  Then, from the command-line:

    % rake deploy:setup to=<target>   (e.g., "qa", "staging", "production", etc.)
    % rake deploy:now   to=<target>

  or, specifying the project name:

    % rake deploy:setup to=<project>:<target>   (e.g., "foo:qa", "bar:production", etc.)
    % rake deploy:now   to=<project>:<target>


### Running from the command-line ###
  
    % wd setup --to=<target>
    % wd setup --to=<project>:<target>
    % wd setup --to=foo:qa --path=/etc/whiskey_disk/deploy.yml
    
    % wd deploy --to=<target>
    % wd deploy --to=<project>:<target>
    % wd deploy --to=foo:qa --path=/etc/whiskey_disk/deploy.yml


Note that the wd command (unlike rake, which requires a Rakefile in the current directory) can be run from anywhere, so you can deploy any project, working from any path, and can even specify where to find the deployment YAML configuration file.
  
The --path argument can take either a file or a directory.  When given a file it will use that file as the configuration file.  When given a directory it will look in that directory for deploy/&lt;project&gt;/&lt;target&gt;.yml, then deploy/&lt;project&gt;.yml, then deploy/&lt;target&gt;.yml, then &lt;target&gt;.yml, and finally, deploy.yml.
  
All this means you can manage a large number of project deployments (local or remote) and have a single scripted deployment manager that keeps them up to date.  Configurations can live in a centralized location, and developers don't have to be actively involved in ensuring code gets shipped up to a server.  Win.


### A note about post\__{setup,deploy} Rake tasks

If you want actions to run on the deployment target after you do a whiskey\_disk setup or whiskey\_disk deploy, 
you will need to make sure that whiskey\_disk is available on the target system (either by gem installation,
as a rails plugin in the Rails application to be deployed, or as a vendored library in the application to be
deployed).  Whiskey\_disk provides the basic deploy:post\_setup and deploy:post\_deploy hooks which get called.
You can also define these tasks yourself if you want to eliminate the dependency on whiskey\_disk on the
deployment target system.

### Staleness checks ###

Enabling staleness checking will cause whiskey\_disk to check whether the deployed checkout of the repository
is out of date ("stale") with respect to the upstream version in git.  If there is a configuration repository
in use, whiskey\_disk will check the deployed checkout of the configuration repository for staleness as well.
If the checkouts are already up-to-date the deployment process will print an up-to-date message and stop rather
than proceeding with any of the deployment actions.  This makes it easy to simply run whiskey\_disk out of cron
so that it will automatically perform a deployment whenever changes are pushed to the upstream git repositories.

To turn on staleness checking, simply set the 'check' environment variable:

    check='yes' wd deploy --to=foobar:production


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
the [larry project](http://github.com/rick/larry) to manage our high-level
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

 

  More Examples:

  - We are using this to manage larry.  See [http://github.com/rick/larry/blob/master/config/deploy.yml](http://github.com/rick/larry/blob/master/config/deploy.yml) and 
    [http://github.com/rick/larry/blob/master/lib/tasks/deploy.rake](http://github.com/rick/larry/blob/master/lib/tasks/deploy.rake)

 - We are using whiskey\_disk on a private project with lots of config files, but here's
    a gist showing a bit more interesting deploy.rake file for post_setup and
post_deploy work:  [https://gist.github.com/47e23f2980943531beeb](https://gist.github.com/47e23f2980943531beeb)

On the radar for an upcoming release are:

 - common post_* recipes being specifiable by symbol names in deploy.yml ?
 - bringing in a very simplified version of mislav/git-deploy post-{receive,reset} hooks, and a little sugar so you can say:

        task :post_deploy do
          if has_changes?('db/migrate') or has_changes?('config/database.yml')
            Rake::Task['db:migrate'].invoke
          end
        end


### Resources ###

 - [http://github.com/blog/470-deployment-script-spring-cleaning](http://github.com/blog/470-deployment-script-spring-cleaning)
 - [http://github.com/mislav/git-deploy](http://github.com/mislav/git-deploy)
 - [http://toroid.org/ams/git-website-howto](http://toroid.org/ams/git-website-howto)


