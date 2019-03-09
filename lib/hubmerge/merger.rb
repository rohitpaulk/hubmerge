module HubMerge
  class RetryError < RuntimeError
  end

  class Merger
    MERGEABILITY_RETRY_COUNT = 5
    MERGEABILITY_RETRY_DELAY = 5

    def self.approve_if_not_approved(gh_client, pr)
      repo = repo_from_pr(pr)
      reviews = gh_client.pull_request_reviews(repo, pr.number)
      unless reviews.find { |review| review.state == "APPROVED" }
        gh_client.create_pull_request_review(repo, pr.number, event: "APPROVE")
      end
    end

    # Returns [is_mergeable, reason_if_not_mergeable]
    def self.check_mergeability(gh_client, pr)
      repo = repo_from_pr(pr)

      with_retries(MERGEABILITY_RETRY_COUNT, MERGEABILITY_RETRY_DELAY) do
        pr = gh_client.pull_request(repo, pr.number)
        if pr.mergeable
          return [true, nil]
        elsif pr.mergeable_state == "unknown"
          raise RetryError
        else
          return [false, pr.mergeable_state]
        end
      end
    end

    def self.merge(gh_client, pr)
      repo = repo_from_pr(pr)
      gh_client.merge_pull_request(repo, pr.number)
    end

    private

    def repo_from_pr(pr)
      pr.base.repo.full_name
    end

    def with_retries(n_tries, delay)
      n_tries.times do
        return yield
      rescue RetryError
        sleep delay
        next
      end
    end
  end
end
