require "test_helper"

class PromptInterrupt < RuntimeError
end

class DummySpinner
  def with_spinner(text)
    yield
  end

  def with_parent(text)
    yield
  end

  def with_child(text)
    yield
  rescue HubMerge::SpinnerError
  end
end

class FakeMerger
  attr_reader :calls
  [:approve_if_not_approved, :check_mergeability, :merge].each do |key|
    define_method(key) do |*args|
      @calls ||= []
      @calls << key
      true
    end
  end
end

class FakePrompts
  attr_reader :prompts

  def initialize(prompts_to_answer)
    @prompts = []
    @prompts_to_answer = prompts_to_answer
  end

  def say(text)
  end

  [:github_token, :repo, :query, :pull_requests_to_merge].each do |key|
    define_method(key) do |*args|
      @prompts << key
      if @prompts_to_answer.key?(key)
        @prompts_to_answer.delete(key)
      else
        raise PromptInterrupt
      end
    end
  end
end

class FakeResultSet
  attr_reader :items

  def initialize(items)
    @items = items
  end
end

class FakeGithubClient
  def initialize(prs)
    @prs = prs
  end

  def search_issues(query)
    FakeResultSet.new(@prs)
  end
end

class FakePR
  attr_reader :number

  def initialize(repo, number)
    @repo = repo
    @number = number
  end
end

class ExecutableTest < Minitest::Test
  def test_no_github_token
    completed = run_exe(["--repo", "rails/rails"], env: {})
    refute completed
    assert_prompt(:github_token)
  end

  def test_no_repo
    completed = run_exe([])
    refute completed
    assert_prompt(:repo)
  end

  def test_repo_but_no_search
    completed = run_exe(["--repo", "rails/rails"])
    refute completed
    assert_prompt(:query)
  end

  def test_no_prs
    gh_client = FakeGithubClient.new([])
    exit_code = run_exe(["--repo", "rails/rails", "--query", "in:title hey"], github_client: gh_client)
    assert_equal 1, exit_code
  end

  def test_no_selected_prs
    exit_code = run_exe(
      ["-r", "rails/rails", "-q", "in:title hey"],
      prompt_answers: {
        pull_requests_to_merge: [],
      }
    )
    assert_equal 1, exit_code
  end

  def test_selected_prs_no_confirm
    exit_code = run_exe(["-r", "rails/rails", "-q", "in:title hey", "-y"])
    assert_equal 0, exit_code
    assert_equal 3, @fake_merger.calls.count
  end

  def test_selected_prs_confirm
    exit_code = run_exe(
      ["-r", "rails/rails", "-q", "in:title hey"],
      prompt_answers: {
        pull_requests_to_merge: [FakePR.new("repo", "number")],
      }
    )
    assert_equal 0, exit_code
    # Mergeability, Approve, Merge
    assert_equal 3, @fake_merger.calls.count
  end

  def test_multiple_prs
    exit_code = run_exe(
      ["-r", "rails/rails", "-q", "in:title hey", "-y"],
      github_client: FakeGithubClient.new([
        FakePR.new("repo", "number"),
        FakePR.new("repo", "number"),
      ])
    )
    assert_equal 0, exit_code
    # 2 x (Mergeability, Approve, Merge)
    assert_equal 6, @fake_merger.calls.count
  end

  private

  def assert_prompt(*keys)
    assert_equal keys, @fake_prompts.prompts
  end

  def run_exe(argv, env: nil, prompt_answers: {}, github_client: nil)
    env = {"GITHUB_TOKEN" => "dummy"} if env.nil?
    if github_client.nil?
      github_client = FakeGithubClient.new([FakePR.new("test", "123")])
    end
    @fake_prompts = FakePrompts.new(prompt_answers)
    @fake_merger = FakeMerger.new
    HubMerge::Executable.new(
      prompts: @fake_prompts,
      github_client: github_client,
      spinner: DummySpinner.new,
      merger: @fake_merger
    ).run(env, argv)
  rescue PromptInterrupt
    nil
  end
end
