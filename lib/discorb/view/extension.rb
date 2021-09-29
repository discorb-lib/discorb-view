module Discorb::View
  module Extension
    attr_accessor :views

    extend Discorb::Extension

    event :button_click do |interaction|
      handle_button_click(interaction)
    end

    def self.extended(base)
      base.views = {}
    end

    class << self
      def handle_button_click(interaction)
        unless view = @client.views[interaction.message.id.to_s]
          @client.log.warn "View: No handler for button click #{interaction.message.id.to_s}"
          return
        end
        handler = view.class.components[interaction.custom_id.to_sym]
        @client.log.debug "View: Handling button click #{interaction.custom_id} in #{interaction.message.id}"
        update = view.instance_exec(interaction, &handler.block)
        return unless update
        @client.log.debug "View: Updating view #{interaction.message.id}"
        view.render(interaction)
      end
    end
  end
end
