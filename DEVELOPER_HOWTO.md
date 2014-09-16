## Gem Developer How To

These instructions are for calabash-ios developers.

These are not instructions for how to use the Calabash iOS BDD framework.

### Run the Tests

##### rspec

If you are writing a new feature or updating an existing one, test it with rspec.

```
$ cd calabash-cucumber
$ be rake spec
```

##### Integration Tests

**WARNING:**

The integration tests will overwrite existing calabash-cucumber/staticlib and calabash-cucumber/dylibs directories.

**You have been warned.**

```
# Run from calabash-ios directory
[calabash-ios] $ script/ci/test/local-run-as-travis.rb

# Requires some configuration; see the script for details.
[calabash-ios] $ script/ci/test/xtc-submit-ci.rb
```

### CI

* https://travis-ci.org/calabash/calabash-ios
* https://travis-ci.org/calabash/run_loop
* https://travis-ci.org/calabash/calabash-ios-server
* Calabash iOS toolchain testing - http://ci.endoftheworl.de:8080/

## Releasing

### Create the release branch

```
$ git co develop
$ git pull
$ git checkout -b release-<next version> develop
```

No more features can be added.  All in-progress features and un-merged pull-requests must wait for the next release.

You can, and should, make changes to the documentation.  You can bump the gem version and the minimum server version.

***You may not touch the gemspec.***  If you need to update a dependency, like run-loop, do so before making the release and make sure the change makes it through CI.

### Create a pull request for the release branch

Do this very soon after you make the release branch to notify the team that you are planning a release.

```
$ git push -u origin release-<next version>
```

Again, no more features can be added to this pull request.  Only changes to documentation are allowed.  You can bump the gem version or change the minimum server version.  _That's it._

### Pre-Flight Checklist

- [ ] Check CI for possible problems.
    * https://travis-ci.org/calabash/run_loop
    * https://travis-ci.org/calabash/calabash-ios-server
    * https://travis-ci.org/calabash/calabash-ios
    * http://ci.endoftheworl.de:8080/ # Briar jobs.
- [ ] Double check that the run-loop version you want to target has been released and is available on the RubyGems site.
    * https://rubygems.org/gems/run_loop

#### Calabash iOS Server

- [ ] You are on the master branch of `calabash-ios-server`.
- [ ] There are no outstanding changes in your local repo.
- [ ] All the required `calabash-ios-server` pull requests have been merged.

#### Calabash iOS Gem

- [ ] You are on the master branch of `calabash-ios`.
- [ ] There are no outstanding changes in your local repo.
- [ ] All the required `calabash-ios` pull requests have been merged.
- [ ] lib/calabash-cucumber/version VERSION is correct
- [ ] lib/calabash-cucumber/version MIN_SERVER_VERSION
- [ ] calabash-cucumber.gemspec points to right version of run-loop

#### Test

Optional: Run a briar-toolchain-masters job on Jenkins [1]

- [1] http://ci.endoftheworl.de:8080/job/briar-toolchain-masters/

The integration tests delete and regenerate the `staticlib` and `dylibs` directories.  Please keep this in mind.

Ideally you should run the rspec _and_ integration tests.  The integration tests re-run a sub-set of the rspec tests; some tests are not stable on Travis CI because of the simulator environment.

These tests will protect you from obvious mistakes, but they are incomplete.  Lean on them, but keep in mind they are a work-in-progress.

#### Rspec

```
[calabash-ios/calabash-cucumber] $ be rake spec
```

##### Integration Tests

```
[calabash-ios] $ script/ci/test/local-run-as-travis.rb

# before
1. uninstall calabash-cucumber 
2. uninstall run_loop
3. install json  # common CI problem

# install latest run-loop from master branch
4. script/ci/travis/clone-and-install-run-loop.rb

# install a set of 'fake' libraries so the gem can install locally
5. script/ci/travis/install-gem-libs.rb

# bundle install to get developer dependencies
6. script/ci/travis/bundle-install.rb

# install the gem locally with rake (not with bundle exec)
7. script/ci/travis/install-gem-ci.rb

# rspec - runs fewer tests than $ be rake spec
8. script/ci/travis/rspec-ci.rb

# clone the calabash-ios-server and build libraries
9. script/ci/travis/rake-build-server-ci.rb

# cucumber against many simulators; includes 1 test with sim_launcher
10. script/ci/travis/cucumber-ci.rb --tags ~@no_ci

# run some dylib tests! woot! dylibs!
11. script/ci/travis/cucumber-dylib-ci.rb
```

##### XTC Tests

_This test is not part of the script/ci/travis/local-run-as-travis.rb_

This test _is_ part of the Travis CI jobs.

```
[calabash-ios] $ export XTC_API_TOKEN=token
[calabash-ios] $ export XTC_DEVICE_SET=set
[calabash-ios] $ script/ci/travis/xtc-submit-ci.rb
```

Alternatively, create a .env file in calabash-cucumber/test/xtc.

```
XTC_API_TOKEN=token
XTC_DEVICE_SET=set
# --async or --no-async
# The default is --no-async (wait for results)
XTC_WAIT_FOR_RESULTS=0
```

_The .env is gitignore'd.  Don't check in your .env file._

#### rake release

Make sure all pull requests have been merged to `develop`

```
# Check CI!
# * https://travis-ci.org/calabash/run_loop
# * https://travis-ci.org/calabash/calabash-ios-server
# * https://travis-ci.org/calabash/calabash-ios
# * http://ci.endoftheworl.de:8080/ # Briar jobs.

# Get the latest develop.
$ git co develop
$ git pull origin develop

# Get the latest master.
$ git co master
$ git pull origin master

# Get the latest release.
$ git fetch
$ git co -t origin/release-<next version>

# Merge release into master, run the tests and push.
$ git co master
$ git merge release-<next version>
$ be rake rspec
$ git push

# Merge release into develop, run the tests and push.
$ git co develop
$ git merge release-<next version>
$ be rake rspec
$ git push

# Delete the release branch
$ git push origin :release-<next version>
$ git br -d release-<next version>

# All is well!
$ git co master
$ gem update --system
$ rake build_server
$ rake release
```
