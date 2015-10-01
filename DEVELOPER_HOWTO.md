## Gem Developer How To

These instructions are for calabash-ios developers.

These are not instructions for how to use the Calabash iOS BDD framework.

### Unit tests

```
$ cd calabash-cucumber
$ be rake unit
```

If you are developing, you should be running guard.

```
$ cd calabash-cucumber
$ be guard
```

Only the unit tests are run with guard.

### Integration tests

The integration tests are in a very bad shape.  The will almost
certainly not pass.

```
$ be rake spec
```

### CI

* https://travis-ci.org/calabash/calabash-ios
* https://travis-ci.org/calabash/run_loop
* https://travis-ci.org/calabash/calabash-ios-server
* Calabash iOS toolchain testing - http://ci.endoftheworl.de:8080/

## Releasing

After the release branch is created:

* No more features can be added.
* All in-progress features and un-merged pull-requests must wait for the next release.
* You can, and should, make changes to the documentation.
* You must bump the version lib/calabash-cucumber/version.  See [VERSIONING.md](VERSIONING.md]).

The release pull request ***must*** be made against the _master_ branch.

Be sure to check CI.

* https://travis-ci.org/calabash/calabash\_ios\_server
* http://ci.endoftheworl.de:8080/  # Briar jobs.

```
$ git co -b release/1.5.0

1. Update the CHANGELOG.md.
2. Bump the version in calabash/Classes/FranklyServer/Routes/LPVersionRoute.h
3. **IMPORTANT** Bump the version in the README.md badge.
3. Have a look at the README.md to see if it can be updated.

$ git push -u origin release/1.5.0

**IMPORTANT**

1. Make a pull request on GitHub on the master branch.
2. Wait for CI to finish.
3. Merge pull request.

$ git co master
$ git pull

$ git tag -a 1.5.0 -m"release/1.5.0"
$ git push origin 1.5.0

$ git co develop
$ git merge --no-ff release/1.5.0
$ git push

$ git branch -d release/1.5.0

Announce the release on the public channels.
```

