require "discorb"
require "discorb/view"

client = Discorb::Client.new

client.extend Discorb::View::Extension

class MyPager
  extend Discorb::View::Base

  @@pages = [
    "Page 1 Content",
    "Page 2 Content",
    "Page 3 Content",
    "Page 4 Content",
  ]

  def initialize
    @page = 0
  end

  select_menu :page, [["Page 1", "1"], ["Page 2", "2"], ["Page 3", "3"], ["Page 4", "4"]], "Page" do |interaction|
    p interaction.value
    @page = interaction.value.to_i - 1
  end

  button :quit, "Quit", :danger do |interaction|
    stop!
  end

  view do |result|
    result.content = @@pages[@page]
    result.embeds = []
    result.components = [:page, :quit]
  end
end

client.once :standby do
  puts "Ready!"
end

client.on :message do |message|
  next unless message.content == "menu"

  MyPager.start(message.channel)
end

client.run ENV["DISCORD_BOT_TOKEN"]
