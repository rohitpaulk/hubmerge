require "octokit"
require "tty-prompt"
require "tty-spinner"

require "hubmerge/version"

require "hubmerge/options"
require "hubmerge/prompts"
require "hubmerge/merger"
require "hubmerge/spinner"

module HubMerge
  class Executable
    def initialize(opts = {})
      # Overrides only used in tests
      @spinner = opts[:spinner] || Spinner.new
      @prompts = opts[:prompts] || Prompts
      @github_client = opts[:github_client]
      @merger = opts[:merger] || Merger
    end

    def run(env, argv)
      check_or_prompt_github_token(env)
      opts = Options.parse(argv)

      query = check_or_prompt_search_query(opts)
      prs = search_pull_requests(query)
      if prs.empty?
        @prompts.say("No pull requests found. Maybe try refining your search query?")
        return 1
      end

      prs_to_merge = if opts[:merge_without_confirmation]
        prs
      else
        @prompts.pull_requests_to_merge(prs)
      end

      if prs_to_merge.empty?
        @prompts.say("No pull requests selected, aborting")
        return 1
      else
        merge_pull_requests(prs_to_merge, opts)
        return 0
      end
    end

    private

    def merge_pull_requests(prs_to_merge, opts)
      total = prs_to_merge.count
      prs_to_merge.each_with_index do |pr, index|
        mergeable = false
        @spinner.with_parent("[:spinner] PR ##{pr.number} (#{index + 1}/#{total})") do
          mergeable = @spinner.with_child("[:spinner] Checking mergeability") {
            begin
              @merger.check_mergeability(github_client, pr)
            rescue UnmergeableError => e
              raise SpinnerError.new("(Mergability: #{e})")
            end

            true
          }

          next unless mergeable

          if opts[:approve_before_merge]
            @spinner.with_child("[:spinner] Approving") do
              @merger.approve_if_not_approved(github_client, pr)
            end
          end

          @spinner.with_child("[:spinner] Merging") do
            @merger.merge(github_client, pr)
          end
        end
      end
    end

    def search_pull_requests(query)
      @spinner.with_spinner("[:spinner] Searching for PRs...") do
        github_client.search_issues(query).items
      end
    end

    def check_or_prompt_search_query(opts)
      if opts.key?(:query) && opts.key?(:repo)
        "is:pr is:open repo:#{opts[:repo]} #{opts[:query]}"
      elsif opts.key?(:query)
        "is:pr is:open #{opts[:query]}"
      else
        repo = opts[:repo] || @prompts.repo(github_client)
        query = @prompts.query
        "is:pr is:open repo:#{repo} #{query}"
      end
    end

    def check_or_prompt_github_token(env)
      @github_token = if env.key?("GITHUB_TOKEN")
        env.fetch("GITHUB_TOKEN")
      else
        @prompts.github_token
      end
    end

    def github_client
      @github_client ||= Octokit::Client.new(access_token: @github_token)
    end
  end
end
