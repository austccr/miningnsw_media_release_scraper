# Archive of NSW Minerals Council media releases

These media releases are important documents of the public record and should be
archived for future analysis.

For each media release, this scraper collects:

* title as `name`
* web address as `url`
* date and time it was collected in UTC, as `scraped_at`
* date it was published (they don't provide a time), as `published`
* the raw string from the source page with the date, as `published_raw`
* authors as `author`
* a summary, if provided, as `summary`
* main body html as `content`
* another place where this article is available, archive.org for example, as `syndication`
* the name of the organisation publishing as `org`
* the featured image of the post as `photo`

These attribute names are loosely based on [the Microformat
h-entry](http://microformats.org/wiki/h-entry) and [h-card](http://microformats.org/wiki/h-card) for `org`.

This scraper runs on the magnificent [morph.io](https:/morph.io).
