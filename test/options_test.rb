require "test_helper"

class OptionsTest < Minitest::Test
  def test_parse_empty
    parsed = HubMerge::Options.parse([])
    assert parsed.empty?
  end

  def test_parse_invalid_option
    assert_raises OptionParser::InvalidOption do
      HubMerge::Options.parse(["--dummy", "abcd"])
    end
  end

  def test_parse_valid
    parsed = HubMerge::Options.parse(["--repo", "rails/rails"])
    assert_equal 1, parsed.count
    assert_equal "rails/rails", parsed[:repo]
  end
end
