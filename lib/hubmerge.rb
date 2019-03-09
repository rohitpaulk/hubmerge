require "octokit"
require "tty-prompt"
require "tty-spinner"

require "hubmerge/version"

module HubMerge
  class Executable
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
        spinners = TTY::Spinner::Multi.new("[:spinner] PR ##{pr.number} (#{index + 1}/#{total})")
        mergeability_spinner = spinners.register("[:spinner] Checking mergeability")
        review_spinner = spinners.register("[:spinner] Approving")
        merge_spinner = spinners.register("[:spinner] Merging")

        mergeability_spinner.auto_spin
        mergeable, error = Merger.check_mergeability(gh_client, pr)
        if mergeable
          mergeability_spinner.success
        else
          mergeability_spinner.error("(Mergability: #{error})")
          next
        end

        review_spinner.auto_spin
        Merger.approve_if_not_approved(gh_client, pr)
        review_spinner.success

        merge_spinner.auto_spin
        Merger.merge(gh_client, pr)
        merge_spinner.success
      end
    end

    def search_pull_requests(query)
      spinner = TTY::Spinner.new("[:spinner] Searching for PRs...")
      spinner.auto_spin
      github_client.search_issues("search_query").items
    ensure
      spinner.stop
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
