require 'scraperwiki'
require 'mechanize'
require 'rest-client'

# TODO: Use https
# There's a problem with their ssl cert, which prevents
# the Wayback machine from archiving and requires not verifying ssl
# on our end. So for now, get the http version.
BASE_URL = 'http://www.nswmining.com.au'
ORG_NAME = 'NSW Mining'

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

def extract_article_body(page)
  page.at('.field-name-body > div > div')&.inner_html ||
    page.at('article .content > div  > div  > div').inner_html
end

def extract_photo(article_item)
  return unless article_item.at('.thumbnail')
  BASE_URL + article_item.at('.thumbnail img')['src']
end

def save_article(article_item, page)
  photo = extract_photo(article_item)
  summary = article_item.at('.exerpt p:last-child').text

  post = page.at('.newsItemDetail')
  published = Date.parse(post.at('.date').text).to_s

  # Skip if we already have the current version of article
  saved_article = ScraperWiki.select("* FROM data WHERE url='#{page.uri.to_s}'").last rescue nil
  if saved_article
    puts "Skipping #{page.uri.to_s}, already saved"
  else
    puts "Saving: #{page.uri.to_s}, #{published}"

    article = {
      'name' => post.at('h1').text,
      'url' => page.uri.to_s,
      'scraped_at' => Time.now.utc.to_s,
      'published' => published,
      'published_raw' => post.at('.date').text,
      'author' => ORG_NAME,
      'summary' => summary,
      'content' => post.inner_html,
      'syndication' => web_archive(page),
      'org' => ORG_NAME
    }
    article['photo'] = photo if photo

    ScraperWiki.save_sqlite(['url'], article)
  end
end

def save_articles_and_click_next_while_articles(agent, index_page)
  web_archive(index_page)

  puts "Collecting articles on #{index_page.uri.to_s}"

  articles = index_page.search('.posts .article')

  if articles.any?
    articles.each do |article_item|
      sleep 1

      save_article(
        article_item,
        agent.get(BASE_URL + article_item.at(:a)['href'])
      )
    end
  end

  next_page_link = index_page.links.select do |link|
    link.text.eql? '>'
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
initial_index_page = agent.get(BASE_URL + "/menu/media/news?page=1")

save_articles_and_click_next_while_articles(
  agent,
  initial_index_page
)
