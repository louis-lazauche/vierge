module BattleUI
  # Abstraction helping to design player choice a way that complies to what Visual expect to handle
  module PlayerChoiceAbstraction
    # Set the choice as wanting to throw a Safari Ball
    # @return [Boolean] if the operation was a success
    def choice_safari_ball
      @result = :safari_ball
      return true
    end

    # Set the choice as wanting to throw a bait
    # @return [Boolean] if the operation was a success
    def choice_bait
      @result = :bait
      return true
    end

    # set the choice as wanting to throw mud
    # @return [Boolean] if the operation was a success
    def choice_mud
      @result = :mud
      return true
    end
  end
end
