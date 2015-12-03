## Versioning

Calabash tries very hard to comply with Semantic Versioning [1] rules.

There are two problems:

1. Calabash 0.x cannot update the major version.  This means that _minor_ releases must be allowed introduce breaking changes.
2. The Semantic versioning spec is incompatible with RubyGem's patterns for pre-release gems.


### Minor Versions

For marketing and technical reasons, we cannot bump the major version of this gem.  When we bump the minor version of the repo, _expect non-backward compatible changes._  We go to great lengths to limit this breaking changes, but sometimes it cannot be helped.  We will document when these changes occur.

### Pre-releases

The semantic versioning spec is incompatible with RubyGem's patterns for pre-release gems.

> "But returning to the practical: No release version of SemVer is compatible with Rubygems." - _David Kellum_ [2]

Calabash version numbers will be in this form:

```
<major>.<minor>.<patch>[.pre<N>]
```

- [1] http://semver.org/
- [2] http://gravitext.com/2012/07/22/versioning.html

