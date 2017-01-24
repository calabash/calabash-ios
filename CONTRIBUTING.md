## About to create a new Github Issue?

We want to reserve the GitHub Issues page for _feature requests_ and _bug reports_.

If you have question please ask it on one of these channels:

* [Calabash iOS Google Group](https://groups.google.com/forum/?fromgroups#!forum/calabash-ios)
* [Stack Overflow with the `#calabash`](http://stackoverflow.com/questions/tagged/calabash).

**Please don't cross post.**  The same people are monitoring the forum and Stack Overflow.  Duplicate posts won't get your question answered faster.

When asking a question or filing a bug report, [please follow the guidelines on the Calabash iOS wiki home page](https://github.com/calabash/calabash-ios/wiki#reporting-problems).

The wiki Home page has [several examples of excellent bug reports](https://github.com/calabash/calabash-ios/wiki#examples-of-good-bug-reports).  You should review one or two of these for tips on how to file a bug report.

If you are pasting code or log output, please use the \`\`\` GitHub code-block formatting.

If you are submitting a pull-request, please read the [Contributing](https://github.com/calabash/calabash-ios/blob/develop/CONTRIBUTING.md#contributing) information below.  Pull-requests without tests or a project to demonstrate the new behavior will probably be rejected.

Please see this [post](http://chris.beams.io/posts/git-commit/) for tips
on how to make a good commit message.

### Xamarin Studio, UITest, and Test Cloud

Xamarin has a two additional support channels for you.  If your question or bug report is UITest or Test Cloud related, your best chance of quick, accurate response will be on one of these channels.

1. [Post your question on the Xamarin Forums](http://forums.xamarin.com/categories/xamarin-test-cloud).
2. [Send and email to support@xamarin.com](mailto:support@xamarin.com)

### CI Environments (Travis, Jenkins, Bamboo, Team City)

Questions or problems with Calabash in CI environments cannot be handled in the GitHub Issues.  Please ask CI related questions on the forums or in Stack Overflow.

## Contributing

***All pull requests should be based off the `develop` branch.***

The Calabash iOS Toolchain uses git-flow.

See these links for information about git-flow and git best practices.

##### Git Flow Step-by-Step guide

* https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow

##### Git Best Practices

* http://justinhileman.info/article/changing-history/

##### git-flow command line tool

We don't use the git-flow tools, but this is useful anyway.

* http://danielkummer.github.io/git-flow-cheatsheet/

## Start a Feature

Start your work on a feature branch based off develop.

```
# If you don't already have the develop branch
$ git fetch origin
$ git checkout -t origin/develop

# If you already have the develop branch
$ git checkout develop
$ git pull origin develop
$ git checkout -b feature/my-new-feature

# Publish your branch and make a pull-request on `develop`
$ git push -u origin feature/my-new-feature
```
