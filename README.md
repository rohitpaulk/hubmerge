# HubMerge

HubMerge helps you merge multiple GitHub Pull Requests with a friendly
[TUI](https://en.wikipedia.org/wiki/Text-based_user_interface).

## Installation

```ruby
gem install hubmerge
```

To authenticate with GitHub, HubMerge expects a `GITHUB_TOKEN` environment
variable to be set. Visit [Github > Settings > Personal Access
Tokens](https://github.com/settings/tokens) to create one. If this is not set,
HubMerge will prompt for the value.

## Usage

HubMerge accepts parameters interactively. Just run `hubmerge` to get started.

    $ hubmerge

You can provide parameters via the CLI too (good to store in your shell history if you do this often!)

    $ hubmerge --repo "rails/rails" --query "author:app/dependabot"

By default, `hubmerge` will always ask for confirmation before merging PRs. If you want to avoid this, use the `--yes` flag. This is useful if you're running `hubmerge` as part of a script.

## Advanced Usage

HubMerge's primary use case is to merge PRs in a single repository. To support
advanced use cases, HubMerge allows using any arbitrary Github [search
filter](https://help.github.com/en/articles/searching-issues-and-pull-requests).

When the `--repo` flag is omitted, the query is directly passed in as a search filter (prefixed with `is:pr is:open`). One can now embed repo/org/user filters into the search query itself.

_Note_: This isn't supported in interactive mode, only via the CLI.

**Multiple repositories**

To merge PRs across multiple repositories:

    $ hubmerge --query "repo:rails/rails repo:sinatra/sinatra author:app/dependabot"

**Organization wide merges**

To merge PRs across an entire org:

    $ hubmerge --query "org:rails author:app/dependabot"

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rohitpaulk/hubmerge.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
