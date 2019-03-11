require 'scraperwiki'
require 'mechanize'
require 'rest-client'

BASE_URL = 'https://www.minerals.org.au'
ORG_NAME = 'Minerals Council of Australia'

def web_archive(page)
  archive_request_response = RestClient.get("https://web.archive.org/save/#{page.uri.to_s}")
  "https://web.archive.org" + archive_request_response.headers[:content_location]
end

def find_meta_tag_content(page, key, value)
  page.search(:meta).find do |t|
    t[key] === value
  end['content']
end

def save_article(page)
  published = find_meta_tag_content(page, :property,'article:published_time')
  updated = find_meta_tag_content(page, :property, 'og:updated_time')

  article = {
    name: find_meta_tag_content(page, :property, 'og:title'),
    url: page.uri.to_s,
    scraped_at: Time.now.utc.to_s,
    published: Time.parse(published).utc.to_s,
    updated: Time.parse(updated).utc.to_s,
    author: page.at('.field-name-field-pbundle-title').text,
    summary: find_meta_tag_content(page, :property, 'og:description'),
    content: page.at('.field-name-body > div > div').inner_html,
    syndication: web_archive(page),
    org: ORG_NAME
  }

  puts "Saving: #{article[:name]}, #{article[:published]}"
  ScraperWiki.save_sqlite([:url, :scraped_at], article)
end

def save_articles_and_click_next_while_articles(agent, index_page)
  web_archive(index_page)

  articles = index_page.search('.view-news-listings .item-list > ul li')

  if articles.any?
    articles.each do |article_item|
      article_url = BASE_URL + article_item.at(:a)['href']

      article_has_been_saved = ScraperWiki.select(
        "url FROM data WHERE url='#{article_url}'"
      ).any? rescue false

      if article_has_been_saved
        puts "Skipping #{article_url}, already saved"
      else
        sleep 2

        save_article(agent.get(article_url))
      end
    end

    next_page_link = index_page.links.select do |link|
      link.text.eql? 'next'
    end.pop

    save_articles_and_click_next_while_articles(
      agent,
      next_page_link.click
    )
  else
    puts "That's the last page my friends, no more posts to collect."
  end
end

agent = Mechanize.new

save_articles_and_click_next_while_articles(
  agent,
  agent.get(BASE_URL + "/media?page=0")
)
