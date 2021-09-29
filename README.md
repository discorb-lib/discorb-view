# Discorb::View

A wrapper of discorb's interaction. This allows you to manage buttons with callbacks.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'discorb-view'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install discorb-view

## Usage

```rb
client.extend Discorb::View::Extension  # Add the extension to your client

class MyMenu
  extend Discorb::View::Base

  @@texts = ["A", "B"]

  def initialize
    @page = 0
  end

  button :left, "<", :primary do |interaction|  # Define a button
    @page -= 1
  end

  button :right, ">", :primary do |interaction|
    @page += 1
  end

  button :quit, "Quit", :danger do |interaction|
    stop!  # Stop the view
  end

  view ->(interaction) { !((0...@@texts.length).include?(@page)) } do |result|  # Define a view that will be shown when the page is out of range
    result.content = "Out of range: Page #{@page + 1}"
  end

  view do |result|  # Define a view that will be shown when the page is in range
    result.content = @@texts[@page % @@texts.length]
    result.embeds = []
    result.components = [:left, :right, :quit]
  end
end

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

client.on :message do |message|
  next if message.author.bot?

  MyMenu.start(message.channel)  if message.content.downcase == "menu"

  MyPager.start(message.channel)  if message.content.downcase == "pager"
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/discorb-lib/discorb-view.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
