module HubMerge
  class Prompts
    def self.repo(github_client)
      TTY::Prompt.new.ask(
        "Enter a GitHub repository to look for PRs in: (example: 'rails/rails')"
      )
    end

    def self.query
      TTY::Prompt.new.ask(
        "Enter a GitHub search query to find PRs (example: 'in:title automerge')",
        default: "author: app/dependabot"
      )
    end

    def self.github_token
      github_token = TTY::Prompt.new.mask(
        "Enter a github access token: (create one at https://github.com/settings/tokens)"
      )
      puts <<~EOF
        To make this easier next time, you can set the `GITHUB_TOKEN` environment variable
      EOF
      github_token
    end

    def self.pull_requests_to_merge(pull_requests)
      choices = pull_requests.map { |pr|
        {
          name: "##{pr.number} - #{pr.title}",
          value: pr,
        }
      }

      TTY::Prompt.new.multi_select(
        "Which of these pull requests do you want to merge? (SPACE to select, ENTER to finalize)",
        choices,
        echo: false,
        per_page: 20,
        filter: true
      )
    end

    def self.say(text)
      puts text
    end
  end
end
