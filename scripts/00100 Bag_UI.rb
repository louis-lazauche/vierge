module GamePlay
  class Bag

    # display only the pockets available for the current mode
    POCKETS_PER_MODE = {
      menu: [1, 6, 3, 4, 5], # Balls, CT, Baies, Objets, Rares
      battle: [1, 2, 6, 4],
      berry: [4],
      hold: [1, 2, 6, 4],
      shop: [1, 6, 3, 4]
    }

    # delete the back button in the item list
    def load_item_list
      if pocket_id == FAVORITE_POCKET_ID
        @item_list = $bag.get_order(:favorites)
      else
        @item_list = $bag.get_order(pocket_id)
      end
      @index = 0
      @last_index = [@item_list.size - 1, 0].max
    end
    alias reload_item_list load_item_list

    # Create all the graphics for the UI
    def create_graphics
      create_viewport
      create_base_ui
      create_static_background
      create_pocket_ui
      create_scroll_bar
      create_bag_sprite 
      create_bag_click_zones
      create_item_list
      create_info
      create_shadow_frame
      Graphics.sort_z

      # 🚀 jouer l’anim du sac sur la poche courante à l’ouverture
      if @bag_sprite
        current_index = @socket_index || 0
        @bag_sprite.animate(current_index)
        @animation = proc { @bag_sprite.update unless @bag_sprite.done? }
      end
    end

    def update_info
      if @item_list.empty?
        @info_wide.clear
        return
      end

      if @socket_index == 2 # si on est dans la poche CT
        @info_wide.show_CT(@item_list[@index], true)
      else
        @info_wide.show_CT(@item_list[@index], false)
      end

      @info_wide.show_item(@item_list[@index])
    end


    def hide_info_if_empty
      @info_wide.show_item(nil)  # => cache tout
      @item_button_list.each { |btn| btn.button_cursor.visible = false }
    end


    # empêche le mode compact de s'activer
    def update_info_visibility
      compact = @compact_mode == :disabled
      @info_compact.visible = false
      @info_wide.visible = true
      @bag_sprite.index = @socket_index
      @bag_sprite.visible = true
    end

    # pas de update arrow ni d'update de bg animé
    def update_graphics
      if @animation
        @animation.call
        @animation = nil if @bag_sprite.done?
      end
      @scroll_bar.button.update
      @item_button_list.each { |btn| btn.button_cursor.update }
      update_bag_click_zones
    end


    def create_static_background
      @static_bg = Sprite.new(@viewport)
      @static_bg.load($trainer.playing_girl ? 'bag/static_bg_girl' : 'bag/static_bg', :interface)
      @static_bg.z = 0
      @static_bg.zoom_x = 1.25
      @static_bg.zoom_y = 1.25
    end

  end
end

#---------------------------------------------------------------------------------------------------------------
#                                         BAG ANIMATED SPRITE
#---------------------------------------------------------------------------------------------------------------
module UI
  module Bag
    class BagSprite < SpriteSheet
      attr_reader :index

      POCKET_TRANSLATION = [0, 1, 2, 3, 4]
      COORDINATES = [0, 21]

      def initialize(viewport, pocket_indexes)
        # chaque poche a 2 frames (final, transition)
        super(viewport, 1, POCKET_TRANSLATION.size * 2)
        @index = 0
        @pocket_indexes = pocket_indexes
        init_sprite
      end

      # empêche le décalage du bagsprite au changement de poche
      def index=(value)
        new_index = value.clamp(0, @pocket_indexes.size - 1)
        return if @index == new_index # évite de rejouer l'anim si on clique sur la même poche
        @index = new_index
        animate(@index)
      end


      # Start the animation : afficher sprite intermédiaire
      def animate(target_index)
        @target_index = target_index
        @counter = 0
        self.sy = transition_frame(@target_index)
      end

      def update
        return if done?
        if @counter == 7
          self.sy = final_frame(@target_index)
        end
        @counter += 1
      end

      def final_frame(index)
        index * 2
      end

      def transition_frame(index)
        index * 2 + 1
      end



      def done?
        @counter >= 8
      end

      def mid?
        @counter == 3
      end

      private

      def init_sprite
        set_bitmap(bag_filename, :interface)
        set_position(*COORDINATES)
        set_origin(0, 0)
        self.zoom_x = 1.25   # élargir 1.5x
        self.zoom_y = 1.25   # agrandir 1.5x
        self.z = 1
      end

      def bag_filename
        $trainer.playing_girl ? 'bag/bag_girl' : 'bag/bag'
      end



    end
  end
end
#---------------------------------------------------------------------------------------------------------------


module UI
  module Bag
    # Class that shows the full item info (descr)
    class InfoWide < SpriteStack
      COORDINATES = 0, 186
      # Change the item it shows
      # @param id [Integer] ID of the item to show

      def initialize(viewport, mode)
        super(viewport, *COORDINATES)
        @mode = mode
        init_sprite
        init_texts
      end

      # @return [ItemSprite]
      def create_icon
        add_sprite(29, 20, NO_INITIAL_IMAGE, type: ItemSprite).set_z(5)
      end

      # @return [Sprite]
      def create_cross
        add_sprite(65, 30, 'bag/num_x').set_z(5)
      end

      # @return [Text]
      def create_quantity_text
        text = add_text(72, 24, 0, 13, nil.to_s, color: 10)
        text.z = 5
        return text
      end

      # @return [Text]
      def create_name_text
        text = add_text(45, 4, 0, 13, nil.to_s, 1, color: 10, sizeid: 6)
        text.z = 5
        return text
      end

      # @return [Text]
      def create_descr_text
        text = add_text(96, 5, 227, 14, nil.to_s, color: 10, sizeid: 6)
        text.z = 5
        return text
      end

      def init_sprite
        create_background
        @icon = create_icon
        @num_x = create_cross
        @quantity = create_quantity_text
        @fav_icon = create_favorite_icon
        @name = create_name_text
        @descr = create_descr_text

        @tm_hm_data = UI::SpriteStack.new(viewport, 100, 50)

        @Power_text_val    = @tm_hm_data.add_text(93, 116, 95, 16, "", color: 10)
        @Accuracy_text_val = @tm_hm_data.add_text(150, 116, 95, 16, "", color: 10)
        @PP_text_val       = @tm_hm_data.add_text(195, 116, 95, 16, "", color: 10)

        @Power_text_val.z = 5000
        @Accuracy_text_val.z = 5000
        @PP_text_val.z = 5000

        @type_sprite     = @tm_hm_data.push(-60, 118, nil, type:TypeSprite)
        @type_sprite.z = 5000
        @category_sprite = @tm_hm_data.push(9, 118, nil, type:CategorySprite)
        @category_sprite.z = 5000

        # Sprite d'information CT
        @ct_info_sprite = add_sprite(0, -23, $trainer.playing_girl ? 'bag/ct_info_sprite_girl' : 'bag/ct_info_sprite', :interface)
        @ct_info_sprite.z = 5
        @ct_info_sprite.visible = false

        # 👇 texte spécial "c'est vide"
        @empty_text = add_text(182, -94, 151, 16, "Vide", color: 10, sizeid: 9)
        @empty_text.z = 5
        @empty_text.visible = false
      end

      def create_background
        add_background($trainer.playing_girl ? 'bag/win_info_wide_girl' : 'bag/win_info_wide').set_z(4)
      end

      def init_texts
        texts = text_file_get(27) 

        # Statique
        @Type_text = add_text(10, -20, 95, 16, texts[3], color: 10)   # "Type"
        @Type_text.visible = false
        @Type_text.z = 5000
        @Category_text = add_text(85, -20, 95, 16, texts[36], color: 10)  # "Catégorie"
        @Category_text.visible = false
        @Category_text.z = 5000
        @Power_text = add_text(164, -20, 95, 16, texts[37], color: 10)  # "Puissance"
        @Power_text.visible = false
        @Power_text.z = 5000
        @Accuracy_text = add_text(221, -20, 95, 16, texts[39], color: 10)  # "Précision"
        @Accuracy_text.visible = false
        @Accuracy_text.z = 5000
        @PP_text = add_text(278, -20, 95, 16, "PP", color: 10)       
        @PP_text.visible = false
        @PP_text.z = 5000
      end

      def show_item(id)
        @empty_text.visible = false  # 👈 cacher le texte quand on montre un item

        unless id
          clear
          return
        end

        item = data_item(id)
        @icon.data = id
        @quantity.text = (id == 0 ? 0 : $bag.item_quantity(id)).to_s.to_pokemon_number
        @num_x.visible = @quantity.visible = item.is_limited

        if item.is_a?(Studio::TechItem)
          @name.text = data_move(item.move).name   # seulement le nom du move

          move = data_move(item.move)
          @tm_hm_data.each do |i|
            i.data = move if i.respond_to?(:data=)
          end
          # 👇 afficher "--" si power ou accuracy = 0
          @Power_text_val.text    = (move.power == 0 ? "--" : move.power.to_s)
          @Accuracy_text_val.text = (move.accuracy == 0 ? "--" : move.accuracy.to_s)
          @PP_text_val.text       = move.pp.to_s
        else
          @name.text = item.exact_name
        end
        @name.visible = true

        @descr.multiline_text = item.descr
        @fav_icon.visible = $bag.shortcuts.include?(item.db_symbol)
      end

      

      def show_CT(id, visible)
        @Type_text.visible = visible
        @Category_text.visible = visible
        @Power_text.visible = visible
        @Accuracy_text.visible = visible
        @PP_text.visible = visible

        @Power_text_val.visible = visible
        @Accuracy_text_val.visible = visible
        @PP_text_val.visible = visible

        @type_sprite.visible = visible
        @category_sprite.visible = visible

        @ct_info_sprite.visible = visible
      end

      def clear
        @icon.data = 0
        @icon.visible = false
        @quantity.text = ""
        @num_x.visible = false
        @name.text = ""
        @descr.text = ""
        @fav_icon.visible = false

        # Si c'était une CT, cacher aussi les champs techniques
        show_CT(nil, false)

        # 👇 afficher le message vide
        @empty_text.visible = true
      end

    end
  end
end


#---------------------------------------------------------------------------------------------------------------
#                                             TM/HM GESTION
#---------------------------------------------------------------------------------------------------------------

module Studio
  class Move
    # ID numérique de la catégorie (Physique, Spécial, Statut)
    def atk_class
      # Retourne 0,1,2 selon la catégorie
      case self.category
      when :physical then 1
      when :special  then 2
      when :status   then 0
      else 0
      end
    end
  end
end


class SpriteSheet < ShaderedSprite
  TYPE_TO_INDEX = {
    normal: 1,
    fire:   2,
    water:  3,
    elektrik: 4,
    grass: 5,
    ice: 6,
    fight: 7,
    poison: 8,
    ground: 9,
    flying: 10,
    psychic: 11,
    bug: 12,
    rock: 13,
    ghost: 14,
    dragon: 15,
    steel: 16,
    dark: 17,
    fairy: 18
  }

  def sy=(value)
    value = TYPE_TO_INDEX[value] if value.is_a?(Symbol)
    @sy = value % @nb_y
    src_rect.y = @sy * src_rect.height
  end
end

#---------------------------------------------------------------------------------------------------------------
#                                             BUTTON IS SELECTED
#---------------------------------------------------------------------------------------------------------------

module GamePlay
  class Bag
    # Dans GamePlay::Bag
    def create_shadow_frame
      # Sprite noir semi-transparent couvrant tout le sac
      @shadow_overlay ||= Sprite.new(@viewport).set_bitmap('choice_window_shadow', :interface)
      @shadow_overlay.opacity = 150  # Ajuste l'intensité du sombre
      @shadow_overlay.z = 500         # Sous le win_text
      @shadow_overlay.visible = false
    end

    def show_shadow_frame
      create_shadow_frame if @shadow_overlay.nil?
      @shadow_overlay.visible = true
    end

    def hide_shadow_frame
      @shadow_overlay&.visible = false
    end
  end
end
#---------------------------------------------------------------------------------------------------------------


# redirecting pokeballs items to the general socket
module PFM
  class Bag
    def add_item_to_order(db_symbol)
      return if @items[db_symbol] <= 0

      if db_symbol.to_s.include?('ball')
        socket = 1
      else
        socket = data_item(db_symbol).socket
      end
      get_order(socket) << db_symbol unless get_order(socket).include?(db_symbol)
    end
  end
end
      
# commenting the back button text
module UI
  module Bag
    class ButtonList < Array
      AMOUNT = 6
      BUTTON_OFFSET = 30
      ACTIVE_OFFSET = 0
      BASE_X = 191
      BASE_Y = 18

      attr_reader :index, :start_index

      def initialize(viewport)
        super(AMOUNT) { |i| ItemButton.new(viewport, i) }
        @item_list = []
        @name_list = []
        @index = 0         # index global (le curseur)
        @start_index = 0   # index global du premier bouton affiché (fenêtre)
      end
      
      def update_cursor(local_pos)
        each_with_index do |btn, i|
          btn.button_cursor.visible = (i == local_pos)
        end
      end

      def item_list=(list)
        @item_list = list
        @name_list = @item_list.collect { |id| data_item(id).exact_name }
        #@name_list << text_get(22, 7)
        # clamp start_index au cas où la liste change
        clamp_start_index!
        update_button_texts
        sync_buttons_positions
      end

      # reçoit l'index global (appelé par Bag via @item_button_list.index = @index)
      def index=(global_index)
        @index = global_index.clamp(0, [@name_list.size - 1, 0].max)

        visible_slots = [AMOUNT, @name_list.size].min

        if @name_list.size < AMOUNT
          # 🚫 Toujours démarrer avec slot 0 vide
          @start_index = -1
        else
          active_slot = find_index(&:active?) || (AMOUNT / 2)
          max_start = [@name_list.size - (visible_slots - 1), 0].max
          min_start = -1
          target_start = @index - active_slot
          @start_index = [[target_start, min_start].max, max_start].min
        end

        update_button_texts
        sync_buttons_positions
      end

      # décale la fenêtre d'affichage de delta (+1 vers le bas, -1 vers le haut)
      def shift_window(delta)
        return if @name_list.empty?

        visible_slots = [AMOUNT, @name_list.size].min

        if @name_list.size < AMOUNT
          # 🚫 Liste trop courte → toujours calée en "partiel" : slot 0 vide
          @start_index = -1
        else
          max_start = [@name_list.size - (visible_slots - 1), 0].max
          min_start = -1  # permet le slot vide
          @start_index = (@start_index + delta).clamp(min_start, max_start)
        end

        update_button_texts
        sync_buttons_positions
        if delta == 1
          update_cursor(AMOUNT-2)
        else
          update_cursor(1)
        end
      end

      def start_index
        @start_index ||= 0
      end
      
      private

      def clamp_start_index!
        max = [@name_list.size - size, 0].max
        @start_index = [[@start_index, 0].max, max].min
      end

      def sync_buttons_positions
        each_with_index do |button, idx|
          button.index = idx
          button.reset
        end
      end

      def update_button_texts
        each_with_index do |btn, i|
          item_index = @start_index + i
          if item_index < 0 || item_index >= @name_list.size
            btn.visible = false
          else
            btn.visible = true
            btn.set_item(@item_list[item_index])
          end
        end
      end

      def button_name(index)
        index < 0 ? nil : @name_list[index]
      end
    end
  end
end


module UI
  module Bag
    # Scrollbar UI element for the bag
    class ScrollBar < SpriteStack
      HEIGHT = 142
      def max_index=(value)
        @max_index = value <= 0 ? 1 : value
        self.index = 0

        # nombre de slots visibles dans la liste
        visible_slots = UI::Bag::ButtonList::AMOUNT

        # 👇 on cache le bouton si la liste tient dans l’écran
        @button.visible = @max_index > visible_slots
      end
      def create_background
        @scrollbar = add_background(BACKGROUND).set_z(1)
        @scrollbar.zoom_x = 1.25
        @scrollbar.zoom_y = 1.25
      end
      def index=(value)
        @index = value.clamp(0, @max_index)
        @button.y = BASE_Y + HEIGHT * @index / @max_index - 2
      end
    end
  end
end

module GamePlay
  class Bag
    
    def button_texts
      return [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "", "", "", "", "", ""]
    end

    def create_base_ui
      @base_ui = UI::GenericBase.new(@viewport, button_texts, bar_on_top: true)
      
      # Déplacer et recréer le win_text pour le sac
      bg = @base_ui.add_sprite(2, 2, 'team/Win_Txt').set_z(502)
      bg.zoom_x = 1.25
      bg.zoom_y = 1.25
      @base_ui.instance_variable_set(:@win_text_background, bg)

      text = @base_ui.add_text(9, 11, 200, 15, nil.to_s, color: 35)
      @base_ui.instance_variable_set(:@win_text, text)

      # Masquer le background et le texte au départ
      bg.visible = false
      text.visible = false

      # --- forcer un premier rendu vide pour initialiser correctement le sprite ---
      @base_ui.show_win_text("")
      @base_ui.hide_win_text
    end

  end
end


#Removing shadows
module GamePlay
  class Bag
    def choice_a_menu
      item_id = @item_list[@index]
      if item_id.nil?
        # do nothing if no item
        return
      end
      return play_buzzer_se if item_id == 0

      item = data_item(item_id)
      play_decision_se
      show_shadow_frame

      choices = PFM::Choice_Helper.new(Yuki::ChoiceWindow, true, 999)

      # Ajouter seulement si l'action est possible
      choices.register_choice(text_get(22, 0), on_validate: method(:use_item)) if item.is_map_usable
      choices.register_choice(text_get(22, 3), on_validate: method(:give_item)) if PFM.game_state.pokemon_alive > 0 && item.is_holdable

      if $bag.shortcuts.include?(item.db_symbol)
        choices.register_choice(text_get(22, 14), on_validate: method(:unregister_item))
      else
        choices.register_choice(text_get(22, 2), on_validate: method(:register_item)) if data_item(item_id).socket == 5
      end

      # Bouton jeter : on garde la proc pour décider si le bouton apparaît
      thr_check = proc { !item.is_limited }
      choices.register_choice(text_get(22, 1), on_validate: method(:throw_item)) if !thr_check.call

      # Ajouter toujours le back/cancel
      choices.register_choice(text_get(22, 7))

      # Afficher le nom de l'objet sélectionné
      @base_ui.show_win_text(parse_text(22, 35, PFM::Text::ITEM2[0] => item.exact_name))
      
      # 🚀 Lancer le blink du curseur GIF
      local_pos = @index - @item_button_list.start_index
      btn = @item_button_list[local_pos]
      btn.button_cursor.start_blink if btn

      # Afficher le choix
      y = 200 - 16 * choices.size
      choices.display_choice(@viewport, 381, 218, 200, on_update: method(:update_graphics), align_right: true)

      @base_ui.hide_win_text
      hide_shadow_frame
    end

    # Choice shown when you press Y on menu mode
    def choice_y_menu
      play_decision_se
      @base_ui.show_win_text(text_get(22, 79))
      choices = PFM::Choice_Helper.new(Yuki::ChoiceWindow, true, 999)
      choices.register_choice(text_get(22, 81), on_validate: method(:sort_name))
             .register_choice(text_get(22, 84), on_validate: method(:sort_number))
             .register_choice(text_get(22, 83), on_validate: method(:sort_quantity_asc))
             .register_choice(text_get(22, 82), on_validate: method(:sort_quantity_desc))
            #  .register_choice(ext_text(9000, 151), on_validate: method(:sort_favorites))
            #  .register_choice(text_get(33, 130), on_validate: method(:search_item))
             .register_choice(text_get(22, 7))
      
      @message_window.y_offset = 200
      # Process the actual choice
      y = 200 - 16 * choices.size
      choices.display_choice(@viewport, 381, 218, 200, on_update: method(:update_graphics), align_right: true)
      @base_ui.hide_win_text 
    end

    # When the player wants to throw an item
    def throw_item
      item_id = @item_list[index = @index]
      item = data_item(item_id)
      return play_buzzer_se unless $bag.contain_item?(item.db_symbol)

      $game_temp.num_input_variable_id = Yuki::Var::EnteredNumber
      $game_temp.num_input_digits_max = $bag.item_quantity(item.db_symbol).to_s.size
      $game_temp.num_input_start = $bag.item_quantity(item.db_symbol)
      PFM::Text.set_item_name(item.exact_name)

      @message_window.y_offset = 200
      @base_ui.hide_win_text
      @base_ui.show_win_text(text_get(22, 38))
      display_message(parse_text(22, 200))
      
      value = $game_variables[Yuki::Var::EnteredNumber]
      if value > 0
        @base_ui.hide_win_text
        @base_ui.show_win_text(parse_text(22, 39, PFM::Text::NUM3[1] => value.to_s))
        display_message(parse_text(22, 200, PFM::Text::NUM3[1] => value.to_s))
        $bag.remove_item(item.db_symbol, value)
        update_bag_ui_after_action(index)
      end
      PFM::Text.reset_variables
    end
    
    # When the player wants to sort the item by name
    def sort_name
      if pocket_id == FAVORITE_POCKET_ID
        shortcuts = $bag.shortcuts[0, 4]
        $bag.shortcuts.shift(4)
        $bag.sort_alpha(:favorites)
        $bag.shortcuts.unshift(*shortcuts)
      else
        $bag.sort_alpha(pocket_id)
      end
      update_bag_ui_after_action(@index)

      @base_ui.hide_win_text
      @base_ui.show_win_text(text_get(22, 69))
      display_message(text_get(22, 69))
    end

    # When the player wants to sort the item by number
    def sort_number
      if pocket_id == FAVORITE_POCKET_ID
        shortcuts = $bag.shortcuts[0, 4]
        $bag.shortcuts.shift(4)
        $bag.reset_order(:favorites)
        $bag.shortcuts.unshift(*shortcuts)
      else
        $bag.reset_order(pocket_id)
      end
      update_bag_ui_after_action(@index)
      @base_ui.hide_win_text
      @base_ui.show_win_text(text_get(22, 86))
      display_message(text_get(22, 86))
    end

    # Tri par quantité croissante
    def sort_quantity_asc
      if pocket_id == FAVORITE_POCKET_ID
        shortcuts = $bag.shortcuts[0, 4]
        $bag.shortcuts.shift(4)
        $bag.sort_by_quantity(:favorites, ascending: true)
        $bag.shortcuts.unshift(*shortcuts)
      else
        $bag.sort_by_quantity(pocket_id, ascending: true)
      end
      update_bag_ui_after_action(@index)

      @base_ui.hide_win_text
      @base_ui.show_win_text(text_get(22, 71))
      display_message(text_get(22, 71))
    end

    # Tri par quantité décroissante
    def sort_quantity_desc
      if pocket_id == FAVORITE_POCKET_ID
        shortcuts = $bag.shortcuts[0, 4]
        $bag.shortcuts.shift(4)
        $bag.sort_by_quantity(:favorites, ascending: false)
        $bag.shortcuts.unshift(*shortcuts)
      else
        $bag.sort_by_quantity(pocket_id, ascending: false)
      end
      update_bag_ui_after_action(@index)

      @base_ui.hide_win_text
      @base_ui.show_win_text(text_get(22, 70))
      display_message(text_get(22, 70))
    end

    # When player wants to use the item
    def use_item
      item_id = @item_list[index = @index]
      return play_buzzer_se unless $bag.contain_item?(item_id)

      util_item_useitem(item_id) do
        @base_ui.hide_win_text
        update_bag_ui_after_action(index)
      end
    end
    # When the player wants to give an item
    def give_item
      item_id = @item_list[index = @index]
      return play_buzzer_se unless $bag.contain_item?(item_id)

      GamePlay.open_party_menu_to_give_item_to_pokemon(item_id) do
        @base_ui.hide_win_text
        update_bag_ui_after_action(index)
      end
    end

    # Dont trigger the search bar
    # Update the bag inputs
    def update_inputs
      # flèches toujours actives
      update_socket_input  

      if @animation
        update_ctrl_button
        return update_list_input
      end

      return update_ctrl_button &&
            update_list_input
    end


    def update_socket_input
      # table des poches autorisées selon le mode
      pockets = POCKETS_PER_MODE[@mode] || []
      return true if pockets.empty?

      old_index = @socket_index || 0

      if Input.trigger?(:LEFT)
        new_index = (old_index - 1) % pockets.size
        change_pocket(new_index)
        play_cursor_se
        return false
      elsif Input.trigger?(:RIGHT)
        new_index = (old_index + 1) % pockets.size
        change_pocket(new_index)
        play_cursor_se
        return false
      end

      return true
    end

    
    # Input update related to the item list
    # @return [Boolean] if another update can be done
    def update_list_input
      old_index = @index
      return true unless index_changed(:@index, :UP, :DOWN, @last_index)

      play_cursor_se
      delta = @index - old_index

      # position locale du curseur dans la fenêtre visible
      local_pos = @index - @item_button_list.start_index
      @item_button_list.update_cursor(local_pos)
      visible_count = @item_button_list.size

      # Mettre à jour la visibilité du GIF
      @item_button_list.each_with_index do |btn, i|
        btn.button_cursor.visible = (i == local_pos)
      end

      if delta.abs == 1
        if local_pos <= 0 && delta < 0
          @item_button_list.shift_window(-1)
          update_info
        elsif local_pos >= visible_count - 1 && delta > 0
          @item_button_list.shift_window(1)
          update_info
        else
          update_info
        end
      else
        update_item_button_list
        update_info
      end

      @scroll_bar.index = @index
      false
    end

    def update_item_button_list
      @item_button_list.item_list = @item_list
      @item_button_list.index = @index
      @scroll_bar.max_index = @item_list.size

      if @item_list.empty?
        @item_button_list.each { |btn| btn.button_cursor.visible = false }
      else
        local_pos = @index - @item_button_list.start_index
        @item_button_list.update_cursor(local_pos)
      end
    end

    # Dans GamePlay::Bag
    def create_bag_click_zones
      return unless @bag_sprite
      @bag_click_sprites ||= []

      # Coordonnées approximatives des 5 zones (x, y, largeur, hauteur)
      zones = [
        [0, 32, 75, 94],  # zone poche 0
        [0, 127, 48, 52], # zone poche 1
        [51, 131, 39, 47], # zone poche 2
        [91, 118, 44, 44], # zone poche 3
        [82, 76, 55, 40]  # zone poche 4
      ]

      zones.each_with_index do |(x, y, w, h), i|
        s = Sprite.new(@viewport)
        s.bitmap = Texture.new(w, h) # bitmap vide
        s.opacity = 0                # transparent
        s.x, s.y = x, y
        s.z = @bag_sprite.z + 1      # au-dessus du bag sprite

        # On stocke le parent scene pour changer de poche
        s.instance_variable_set(:@parent_scene, self)

        # Détection du clic
        s.define_singleton_method(:update) do
          parent = instance_variable_get(:@parent_scene)
          if Mouse.trigger?(:LEFT) && Mouse.x.between?(x, x + w) && Mouse.y.between?(y, y + h)
            parent.change_pocket(i) if parent
          end
        end

        @bag_click_sprites << s
      end
    end
    def update_bag_click_zones
      return unless @bag_click_sprites
      @bag_click_sprites.each(&:update)
    end

    def change_pocket(new_index)
      return if @socket_index == new_index
      @socket_index = new_index
      @pocket_ui.index = new_index
      @bag_sprite.index = new_index   # déclenche animate
      @animation = proc { @bag_sprite.update unless @bag_sprite.done? } # 👈 boucle anim

      update_pocket_name
      reload_item_list
      update_scroll_bar
      update_item_button_list
      update_info
    end


    public :change_pocket

  end
end


module PFM
  class Bag
    # Trie les objets d'une poche par quantité
    # @param socket [Integer, Symbol] poche ou :favorites
    # @param ascending [Boolean] true = croissant, false = décroissant
    def sort_by_quantity(socket, ascending: true)
      order = get_order(socket)
      order.sort_by! { |id| item_quantity(id) }
      order.reverse! unless ascending
    end
  end
end


module UI
  class ScrollBarGif < Sprite
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'bag', 'scrollbar.gif')
      @gif_reader = Yuki::GifReader.new(path)
      self.bitmap = Texture.new(@gif_reader.width, @gif_reader.height)
      @gif_reader.update(self.bitmap)
      set_origin(0, 0)
    end

    def update
      @gif_reader&.update(bitmap)
    end
  end
end

module UI
  class ButtonSelectGif < Sprite
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'bag', 'button_select.gif')
      @gif_reader = Yuki::GifReader.new(path)
      self.bitmap = Texture.new(@gif_reader.width, @gif_reader.height)
      @gif_reader.update(self.bitmap)
      set_origin(0, 0)

      # Blink variables
      @blink_counter = 0
      @blink_phase = :off
      @blink_active = false
    end

    # Lance le blink
    def start_blink
      @blink_counter = 0
      @blink_phase = :off
      @blink_active = true
    end

    def update
      @gif_reader&.update(bitmap)

      return unless @blink_active

      # Gestion du blink : 4 phases (off/on/off/on)
      @blink_counter += 1
      case @blink_counter
      when 1..3
        self.visible = false
      when 4..6
        self.visible = true
      when 7..9
        self.visible = false
      when 10..12
        self.visible = true
      else
        @blink_active = false
        self.visible = true
      end
    end
  end
end


module UI
  module Bag
    # Scrollbar UI element for the bag
    class ScrollBar < SpriteStack
      attr_reader :button
      def create_button
        btn = push(-3, 0, nil, type: ScrollBarGif)
        btn.zoom_x = 1.25
        btn.zoom_y = 1.25
        btn.z = 10
        btn
      end
    end
  end
end



module UI
  module Bag
    # List of button showing the item name
    class ButtonList < Array
      class ItemButton < SpriteStack
        attr_reader :button_cursor
        def initialize(viewport, index)
          @index = index
          super(viewport, BASE_X + (active? ? ACTIVE_OFFSET : 0), BASE_Y + BUTTON_OFFSET * index)
          create_background
          @button_cursor = create_button_gif
          @item_name = add_text(-11, 6, 0, 13, "", color: 10, sizeid: 9)   # couleur normale
          @item_name_hm = add_text(-11, 6, 0, 13, "", color: 34, sizeid: 9) # couleur HM/TM
          @item_name_hm.visible = false
        end

        def create_button_gif
          # Création du curseur GIF (indépendant des ItemButton)
          btn_cursor = push(-18, -1, nil, type: ButtonSelectGif)
          btn_cursor.z = 0
          btn_cursor.zoom_x = 1.25
          btn_cursor.zoom_y = 1.25
          btn_cursor
        end

        def create_text(db_symbol = nil)
          color = if db_symbol && UI::Bag::BUTTON_SKINS[:hms].include?(db_symbol)
                    18
                  else
                    10
                  end
          text = add_text(7, 4, 0, 13, nil.to_s, color: color)
          text.z = 2
          text
        end

      end
    end
  end
end

module UI
  module Bag
    # List of button showing the item name
    class ButtonList < Array
      class ItemButton < SpriteStack
        def create_background
          @background = add_sprite(0, 0, 'bag/button_default', :interface)
          @background.zoom_x = 1.25
          @background.zoom_y = 1.25
        end

        def set_item(item_id)
          return unless item_id

          item = data_item(item_id)
          skin = skin_for(item.db_symbol)

          # Déterminer le texte à afficher
          display_name = if item.is_a?(Studio::TechItem)
                          data_move(item.move).name   # juste le nom du mouvement
                        else
                          item.exact_name
                        end

          # Affichage du texte selon le skin
          if UI::Bag::BUTTON_SKINS[:hms].include?(item.db_symbol)
            @item_name.visible = false
            @item_name_hm.visible = true
            @item_name_hm.text = display_name
          else
            @item_name.visible = true
            @item_name_hm.visible = false
            @item_name.text = display_name
          end

          # Définir le skin du bouton
          @background.bitmap = RPG::Cache.interface("bag/#{skin}")

          # Toujours remettre la position par défaut
          @background.x = 173

          # Déplacement spécifique selon skin
          case skin
          when "button_tm", "button_hm"
            @background.x = 150
          when "button_ball", "button_object"
            @background.x = 154
          end
        end


        private

        def skin_for(symbol)
          if UI::Bag::BUTTON_SKINS[:balls].include?(symbol)
            "button_ball"
          elsif UI::Bag::BUTTON_SKINS[:objects].include?(symbol)
            "button_object"
          elsif UI::Bag::BUTTON_SKINS[:tms].include?(symbol)
            "button_tm"
          elsif UI::Bag::BUTTON_SKINS[:hms].include?(symbol)
            "button_hm"
          else
            "button_default"
          end
        end
      end
    end
  end
end


module UI
  module Bag
    BUTTON_SKINS = {
      balls: %i[poke_ball great_ball ultra_ball master_ball], # to complete
      objects: %i[big_root miracle_seed leftovers choice_scarf], # to complete
      hms: %i[hm01 hm02 hm03 hm04 hm05 hm06 hm07 hm08], 
      tms: %i[tm01 tm02 tm03 tm04 tm05 tm06 tm07 tm08 tm09 tm10 tm11 tm12 tm13 tm14 tm15 tm16 tm17 tm18 tm19 tm20 tm21 tm22 tm23 tm24 tm25 tm26 tm27 tm28 tm29 tm30 tm31 tm32 tm33 tm34 tm35 tm36 tm37 tm38 tm39 tm40 tm41 tm42 tm43 tm44 tm45 tm46 tm47 tm48 tm49 tm50 tm51 tm52 tm53 tm54 tm55 tm56 tm57 tm58 tm59 tm60 tm61 tm62 tm63 tm64 tm65 tm66 tm67 tm68 tm69 tm70 tm71 tm72 tm73 tm74 tm75 tm76 tm77 tm78 tm79 tm80 tm81 tm82 tm83 tm84 tm85 tm86 tm87 tm88 tm89 tm90 tm91 tm92 tm93 tm94 tm95]
    }
  end
end

module UI
  module Bag
    # UI element showing the name of the Pocket in the bag
    class WinPocket < SpriteStack
      def create_text
        text = add_text(34, 2, 87, 13, nil.to_s, 1, color: 10, sizeid: 9)
        text.z = 501
        return text
      end
    end
  end
end


module Studio
  # Data class describing an Item that allow a creature to learn a move
  class TechItem < Item
    def move_name_only
      data_move(move).name
    end
  end
end

module UI
  # UI element showing input number (for number choice & selling)
  class InputNumber < SpriteStack
    IMAGE_COMPOSITION = {
      left: [0, 0, 18, 48],
      number: [18, 0, 6, 48],
      separator: [24, 0, 1, 48],
      right: [25, 0, 127, 48],
      money_add: [129, 0, 35, 48]
    }
    def define_position
      # Exemple : garder l’alignement à droite mais ajouter un petit décalage
      self.x = @viewport.rect.width - width
    end

    def draw_digits
      @money_text&.text = parse_text(11, 9, /\[VAR NUM7[^\]]*\]/ => (@number * $game_temp.shop_calling).to_s)

      @number.to_s.ljust(@max_digits, ' ').each_char.with_index do |char, index|
        @texts[index].text = char
        @texts[index].load_color(36)
      end
    end

    def create_center
      current_x = @width_accounting_sprites.last.width
      width = IMAGE_COMPOSITION[:number][-2]
      height = IMAGE_COMPOSITION[:number][-1]
      1.step(@max_digits - 1) do
        @width_accounting_sprites << add_sprite(current_x, 0, IMAGE_SOURCE, rect: IMAGE_COMPOSITION[:number])
        @texts << add_text(current_x, -98, width, height, nil.to_s, 1)
        current_x += @width_accounting_sprites.last.width
        @width_accounting_sprites << add_sprite(current_x, 0, IMAGE_SOURCE, rect: IMAGE_COMPOSITION[:separator])
        current_x += @width_accounting_sprites.last.width
      end
      # Last text/sprite
      @width_accounting_sprites << add_sprite(current_x, 0, IMAGE_SOURCE, rect: IMAGE_COMPOSITION[:number])
      @texts << add_text(current_x, -98, width, height, nil.to_s, 1)
      current_x += @width_accounting_sprites.last.width
    end

    def create_sprites
      create_left
      create_center
      create_right
      create_money
      define_position
      @width_accounting_sprites.each { |s| s.zoom_x = 1.25; s.zoom_y = 1.25 }
      @width_accounting_sprites.each { |s| s.y -= 94 } # ajuster la position verticale
    end
  end
end


class UI::Message::Window
  attr_accessor :y_offset

  alias update_y_offset update
  def update
    self.y = 50 + (y_offset || 0)
    update_y_offset
  end
end


