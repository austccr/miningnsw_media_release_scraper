# An collect an archive of Minerals Council of Australia media releases

These media releases are important documents of the public record and should be
archived for future analysis.

For each media release, this scraper collects:

* title as `name`
* web address as `url`
* date and time it was collected in UTC, as `scraped_at`
* date and time published in UTC, as `published`
* date and time updated in UTC, as `updated`
* authors as `author`
* a summary, if provided, as `summary`
* main body html as `content`
* another place where this article is available, archive.org for example, as `syndication`
* the name of the organisation publishing as `org`

These attribute names are loosely based on [the Microformat
h-entry](http://microformats.org/wiki/h-entry) and [h-card](http://microformats.org/wiki/h-card) for `org`.

This scraper runs on the magnificent [morph.io](https:/morph.io).

## TODO

* [ ] Get the PDFs referenced in the article and archive them.
* [ ] handle post updates somehow.
