class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    @categories = {
      "General web development" => [
        { title: "CSS-Tricks", url: "https://css-tricks.com/feed/" }
        #{ title: "Smashing Magazine", url: "https://www.smashingmagazine.com/feed/" },
        #{ title: "SitePoint", url: "https://www.sitepoint.com/feed/" },
        #{ title: "Webdesigner News", url: "https://www.webdesignernews.com/rss" }
      ],
      "Front-end web development" => [
        { title: "CSS Weekly", url: "https://css-weekly.com/rss" }
        #{ title: "JavaScript Weekly", url: "https://javascriptweekly.com/rss/1n8hl6o5" },
        #{ title: "React Status", url: "https://react.statuscode.com/rss.xml" },
        #{ title: "Vue.js Newsletter", url: "https://news.vuejs.org/feed.xml" }
      ],
      "Back-end web development" => [
        { title: "Ruby Weekly", url: "https://rubyweekly.com/rss/1p5irj1k" }
        #{ title: "Node Weekly", url: "https://nodeweekly.com/rss/1dndcrvh" }
      ]
    }
    @feed_items = {}
    @categories.each do |category, sources|
      @feed_items[category] = []
      sources.each do |source|
        cache_key = source[:url]
        puts "Cache key: #{cache_key}"
        rss = Rails.cache.fetch(cache_key, expires_in: 240.minutes) do
          puts "Cache miss: #{cache_key}"
          RSS::Parser.parse(URI.open(cache_key).read, false).items
        end
        puts "Cache hit: #{cache_key}" if rss.present?
        rss.each do |item|
          @feed_items[category] << { title: item.title, url: item.link }
        end
      end
    end

  end
end
