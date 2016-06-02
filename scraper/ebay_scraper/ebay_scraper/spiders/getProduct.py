# -*- coding: utf-8 -*-
import scrapy
from scrapy.selector import HtmlXPathSelector

from ebay_scraper.items import EbayScraperItem


class GetproductSpider(scrapy.Spider):
    name = "getProduct"
    allowed_domains = ["www.amazon.com"]
    start_urls = (
        'http://www.amazon.com/Cuisinart-GR-4NR-Griddler-Silver-Dials/dp/B016B40XT6/ref=sr_1_13?ie=UTF8&qid=1464894566&sr=8-13&keywords=red',
    )

    def parse(self, response):
        hxs = HtmlXPathSelector(response)
        titles = hxs.xpath("//span[@id='productTitle']")
        items = []
        for titles in titles:
            item = EbayScraperItem()
            title = str(titles.select("text()").extract())
            title = title[1:-1]     # Remove quots
            title = title.replace("\\n","")
            # title = title.rstrip()
            item["title"] = title

            items.append(item)
        return items
