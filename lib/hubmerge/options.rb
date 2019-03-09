module HubMerge
  class Options
    def self.all
      {
        repo: {
          short_switch: "-r",
          long_switch: "--repo ORG/REPONAME",
          type: String,
          description: "Github repository to search for PRs in (example: rails/rails)",
        },

        query: {
          short_switch: "-q",
          long_switch: "--query ORG/REPONAME",
          type: String,
          description: "GitHub search query to run to find PRs (example: 'author:app/dependabot')",
        },

        merge_without_confirmation: {
          short_switch: "-y",
          long_switch: "--yes",
          type: :flag,
          description: "Merge without confirmation from user (default: false)",
        },
      }
    end

    def self.parse(argv)
      parsed = {}
      opt_parser = OptionParser.new

      all.each do |key, params|
        if params[:type] == :flag
          opt_parser.on(
            params[:short_switch],
            params[:long_switch],
            params[:description]
          ) { |v| parsed[key] = v }
        else
          opt_parser.on(
            params[:short_switch],
            params[:long_switch],
            params[:type],
            params[:description]
          ) { |v| parsed[key] = v }
        end
      end

      opt_parser.parse(argv)
      parsed
    end
  end
end
