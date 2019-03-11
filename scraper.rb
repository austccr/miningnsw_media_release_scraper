require 'scraperwiki'
require 'mechanize'
require 'rest-client'

# TODO: Use https
# There's a problem with their ssl cert, which prevents
# the Wayback machine from archiving and requires not verifying ssl
# on our end. So for now, get the http version.
BASE_URL = 'http://minerals.org.au'
ORG_NAME = 'Minerals Council of Australia'
DEFAULT_AUTHOR = 'MCA National'

def web_archive(page)
  url = "https://web.archive.org/save/#{page.uri.to_s}"

  begin
    archive_request_response = RestClient.get(url)
    "https://web.archive.org" + archive_request_response.headers[:content_location]
  rescue RestClient::BadGateway => e
    puts "archive.org ping returned error response for #{url}: " + e.to_s
  end
end

def find_meta_tag_content(page, key, value)
  tag = page.search(:meta).find do |t|
    t[key] === value
  end

  tag['content'] if tag
end

def extract_author_or_default(page)
  page.at('.field-name-field-pbundle-title')&.text || DEFAULT_AUTHOR
end

def extract_article_body(page)
  page.at('.field-name-body > div > div')&.inner_html ||
    page.at('article .content > div  > div  > div').inner_html
end

def parse_utc_time_or_nil(string)
  Time.parse(string).utc.to_s if string
end

def save_article(page)
  published = find_meta_tag_content(page, :property,'article:published_time')
  updated = find_meta_tag_content(page, :property, 'og:updated_time')

  article = {
    'name' => find_meta_tag_content(page, :property, 'og:title'),
    'url' => page.uri.to_s,
    'scraped_at' => Time.now.utc.to_s,
    'published' => parse_utc_time_or_nil(published),
    'updated' => parse_utc_time_or_nil(updated),
    'author' => extract_author_or_default(page),
    'summary' => find_meta_tag_content(page, :property, 'og:description'),
    'content' => extract_article_body(page),
    'syndication' => web_archive(page),
    'org' => ORG_NAME,
    'photo' => find_meta_tag_content(page, :property, 'og:image')
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
        sleep 1

        save_article(agent.get(article_url))
      end
    end

  end

  next_page_link = index_page.links.select do |link|
    link.text.eql? 'next'
  end.pop

  if next_page_link
    puts "Clicking for the next page"

    save_articles_and_click_next_while_articles(
      agent,
      next_page_link.click
    )
  else
    puts "That's the last page my friends, no more articles to collect."
  end
end

agent = Mechanize.new

initial_index_page = agent.get(BASE_URL + "/media?page=0")

save_articles_and_click_next_while_articles(
  agent,
  initial_index_page
)
