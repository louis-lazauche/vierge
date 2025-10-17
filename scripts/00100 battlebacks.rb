module BattleUI
  class BattleBackExample < Battleback3D
    def initialize(viewport, scene)
      super
    end


    def create_graphics
      # Ground Sprites
      @background = add_battleback_element(@path, 'bg')
      @background.x = -300
      @pokeislands = add_battleback_element(@path, 'pi')
    end

    # Return the path for the resources
    def resource_path
      return 'animated_camera/battleback_example/'
    end
  end
end


module Battle
  class Visual3D < Visual
    def create_background
      case background_name
      when "back_grass"
        @background = BattleUI::BattleBackGrass.new(viewport, @scene)
      when "BattleBackExample"
        @background = BattleUI::BattleBackExample.new(viewport, @scene) # Change the class name by yours
      else
        @background = BattleUI::BattleBackExample.new(viewport, @scene) # Change the class name by yours
      end
    end
  end
end