## Yard Docs

The gem is documented with a mix of rdoc and yard.  We are migrating old rdocs to yard and writing new docs with yard.

### Build the Docs Locally

```
$ be rake yard
Files:          38
Modules:        26 (   13 undocumented)
Classes:        14 (   11 undocumented)
Constants:      31 (   21 undocumented)
Methods:       466 (  242 undocumented)
 46.55% documented
```

Docs are generated in the `docs` directory.

### Start a Local Server

```
$ be yard server
> YARD 0.8.7.3 documentation server at http://0.0.0.0:8808
[2014-02-25 13:17:46] INFO  WEBrick 1.3.1
[2014-02-25 13:17:46] INFO  ruby 2.0.0 (2013-11-22) [x86_64-darwin13.0.0]
[2014-02-25 13:17:46] INFO  WEBrick::HTTPServer#start: pid=54296 port=8808
```

View docs here: http://0.0.0.0:8808

When writing docs, it is usual to run:

```
# Reparses the library code on each request
$ be yard server --reload
```

### Documenting with Yard

* http://yardoc.org/
* https://github.com/lsegal/yard
* http://yardoc.org/guides/index.html
* http://yardoc.org/types.html

The Yard syntax should be familiar to anyone who has used javadocs or doyxgen.

This page has details about the Yard markup tags and is extremely useful:

* [list of yard tags](http://rubydoc.info/gems/yard/file/docs/Tags.md#List_of_Available_Tags)

The following files have good examples of yard format:

```
lib/calabash-cucumber/utils/plist_buddy.rb
lib/calabash-cucumber/utils/simulator_accessibility.rb
lib/calabash-cucumber/utils/xctools.rb

```

and `keyboard_helpers.rb` is a good example of comprehensive documentation (it is in rdoc - pull requests welcome).


### Examples

```
# method for interacting with instruments
#
#              instruments #=> /Applications/Xcode.app/Contents/Developer/usr/bin/instruments
#    instruments(:version) #=> 5.1.1
#       instruments(:sims) #=> < list of known simulators >
#
# @param [String] cmd controls the return value.  currently accepts nil,
#   :sims, and :version as valid parameters
# @return [String] based on the value of +cmd+ version, a list known
#   simulators, or the path to the instruments binary
# @raise [ArgumentError] if invalid +cmd+ is passed
```

#### code blocks

Indent code blocks 2 or more spaces.

```
#              instruments #=> /Applications/Xcode.app/Contents/Developer/usr/bin/instruments
#    instruments(:version) #=> 5.1.1
#       instruments(:sims) #=> < list of known simulators >
```

#### tags that span multiple lines

Indent subsequent lines by 2 or more spaces (prefer 2 spaces).

```
# @param [String] cmd controls the return value.  currently accepts nil,
#   :sims, and :version as valid parameters
```

#### default argument values are auto-generated

A method like this:

```
# @param [String] cmd controls the return value.  currently accepts nil,
#   :sims, and :version as valid parameters
def instruments(cmd=nil)
```

will generate:

```
cmd (String) (defaults to: nil) — controls the return value. currently accepts nil, :sims, and :version as valid parameters
```

#### documenting option hashes

Default values can be specified by including them after the option key in `()`.

```
# @param [Hash] opts controls the content of the query string
# @option opts [Integer,nil] :with_tag (true) if non-nil the query string includes tag filter
# @option opts [Integer,nil] :with_clips_to_bounds (false) if non-nil the query string includes clipsToBounds filter
```

#### multiple return values

You can list multiple return tags for a method in the case where a method has distinct return cases.   Each case should begin with “if …”

```
# @return [nil] if +key+ does not exist
# @return [String] if the +key+ exists then the value of +key+ (error)
```

You can also chain return values.

```
# Finds an object or list of objects in the db using a query
# @return [String, Array<String>, nil] the object or objects to
#   find in the database. Can be nil.
def find(query) finder_code_here end
```

#### generics are allowed

```
# @param [Array<String, Integer, Float>] list a list of strings integers and floats
```

#### ignoring private APIs

The [.yardopts](./.yardopts) file includes the `--no-private` option.

To mark an object as private, use the one of the following tags:

* `@private` <== preferred
* `@!visibility private`

```
# @private
# if +msg+ is a String, a new WaitError is returned. Otherwise +msg+
# ...
def wait_error(msg)
  (msg.is_a?(String) ? WaitError.new(msg) : msg)
end
```

```
# @!visibility private
# raises an error by raising a exception and conditionally takes a
# screenshot based on the value of +screenshot_on_error+.
# ...
def handle_error_with_options(ex, timeout_message, screenshot_on_error)
```
