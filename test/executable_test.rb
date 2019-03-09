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
  rescue SpinnerError
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

  [:github_token, :repo, :query].each do |key|
    define_method(key) do |*args|
      @prompts << key
      if @prompts_to_answer.key?(key)
        @prompts_to_answer.pop(key)
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
    fake_gh = FakeGithubClient.new([])
    exit_code = run_exe(["--repo", "rails/rails", "--query", "in:title hey"], github_client: fake_gh)
    assert_equal 1, exit_code
  end

  def assert_prompt(*keys)
    assert_equal keys, @fake_prompts.prompts
  end

  def run_exe(argv, env: nil, prompt_answers: {}, github_client: {})
    @fake_prompts = FakePrompts.new({})
    env = {"GITHUB_TOKEN" => "dummy"} if env.nil?
    HubMerge::Executable.new(
      prompts: @fake_prompts,
      github_client: github_client,
      spinner: DummySpinner.new
    ).run(env, argv)
  rescue PromptInterrupt
    nil
  end
end
