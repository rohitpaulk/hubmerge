require "octokit"
require "tty-prompt"
require "tty-spinner"

require "hubmerge/version"

require "hubmerge/options"
require "hubmerge/prompts"
require "hubmerge/merger"

module HubMerge
  class Executable
    def initialize(opts = {})
      @spinner = opts[:spinner] || Spinner.new
    end

    def run(env, argv)
      check_or_prompt_github_token(env)
      opts = Options.parse(argv)

      # help?

      query = check_or_prompt_search_query(opts)
      prs = search_pull_requests(query)
      prs_to_merge = Prompts.pull_requests_to_merge(prs)
      if prs_to_merge.empty?
        puts "No pull requests selected, aborting"
        exit 1
      end

      merge_pull_requests(prs_to_merge)
    end

    private

    def merge_pull_requests(prs_to_merge)
      total = prs_to_merge.count
      prs_to_merge.each_with_index do |pr, index|
        @spinner.with_parent("[:spinner] PR ##{pr.number} (#{index + 1}/#{total})") do
          mergeable = @spinner.with_child("[:spinner] Checking mergeability") {
            begin
              Merger.check_mergeability(gh_client, pr)
            rescue UnmergeableError => e
              raise SpinnerError("(Mergability: #{e})")
            end
          }

          next unless mergeable

          @spinner.with_child("[:spinner] Approving") do
            Merger.approve_if_not_approved(gh_client, pr)
          end

          @spinner.with_child("[:spinner] Merging") do
            Merger.merge(gh_client, pr)
          end
        end
      end
    end

    def search_pull_requests(query)
      @spinner.with_spinner("[:spinner] Searching for PRs...") do
        github_client.search_issues("search_query").items
      end
    end

    def check_or_prompt_search_query(opts)
      if opts.key?(:query) && opts.key?(:repo)
        "is:pr is:open repo:#{opts[:repo]} #{opts[:query]}"
      elsif opts.key?(:query)
        "is:pr is:open #{opts[:query]}"
      else
        repo = Prompts.repo(github_client)
        query = Prompts.query
        "is:pr is:open repo:#{repo} #{query}"
      end
    end

    def check_or_prompt_github_token(env)
      @github_token = if env.key?("GITHUB_TOKEN")
        env.fetch("GITHUB_TOKEN")
      else
        Prompts.github_token
      end
    end

    def github_client
      @github_client ||= Octokit::Client.new(access_token: @github_token)
    end
  end
end
