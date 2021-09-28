module Discorb::View
  class Extension
    attr_accessor :views

    extend Discorb::Extension

    event :button_click do |interaction|
      handle_button_click(interaction)
    end

    def view_handlers
      @views.map { |view| view.handlers }.flatten.map { |handler| [handler.name, handler] }.to_h
    end

    def self.extended(base)
      base.views = {}
    end

    class << self
      def handle_button_click(interaction)
        unless handler = @client.view_handlers[interaction.custom_id]
          @client.log.warn "View: No handler for button click #{interaction.custom_id}"
          return
        end
        @client.log.debug "View: Handling button click #{interaction.custom_id}"
        handler.call(interaction)
      end
    end
  end
end
