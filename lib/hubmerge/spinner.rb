module HubMerge
  class SpinnerError < RuntimeError
  end

  class Spinner
    def initialize
      @active_parent_spinner = nil
    end

    def with_spinner(text)
      spinner = TTY::Spinner.new(text)
      spinner.auto_spin
      yield
    ensure
      spinner.stop
    end

    def with_parent(text)
      @active_parent_spinner = TTY::Spinner::Multi.new(text)
      yield
    ensure
      @active_parent_spinner = nil
    end

    def with_child(text)
      ensure_active_parent!

      spinner = @active_parent_spinner.register(text)
      spinner.auto_spin
      result = yield
      spinner.success
      result
    rescue SpinnerError => e
      spinner.error(e.to_s)
      result
    end

    def ensure_active_parent!
      unless !!@active_parent_spinner
        raise "#with_parent not called!"
      end
    end
  end
end
