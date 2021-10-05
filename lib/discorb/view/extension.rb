module Discorb::View
  #
  # An extension for using discorb-view.
  # @note Client must extend this class to use discorb-view.
  #
  class Extension < Discorb::Extension
    event :button_click do |interaction|
      handle_interaction(interaction)
    end

    event :select_menu_select do |interaction|
      handle_interaction(interaction)
    end

    # @private
    def self.inherited(base)
      base.views = {}
    end

    # @private
    def handle_interaction(interaction)
      unless view = @client.views[interaction.message.id.to_s]
        @client.log.warn "View: No handler for #{interaction.message.id.to_s}"
        return
      end
      handler = view.class.components[interaction.custom_id.to_sym]
      @client.log.debug "View: Handling #{interaction.custom_id} in #{interaction.message.id}"
      view.interaction = interaction
      update = view.instance_exec(interaction, &handler.block)
      return unless update
      @client.log.debug "View: Updating view #{interaction.message.id}"
      view.render
    end

    def self.loaded(client)
      class << client
        attr_accessor :views
      end
      client.views = {}
    end
  end
end
