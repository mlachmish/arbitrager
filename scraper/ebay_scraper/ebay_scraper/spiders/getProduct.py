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
        titles = hxs.xpath("string(//span[@id='productTitle'])").extract()
        price = hxs.xpath("string(//span[@id='priceblock_dealprice'])").extract()
        stock = hxs.xpath("//div[@id='availability']/span")
        description = hxs.xpath("//div[@id='feature-bullets']/ul/li//span")
        images = hxs.xpath("//img[contains(@class, 'a-dynamic-image') and contains(@class, 'a-stretch-vertical')][@src][1]")

        #print "########################################################################################################################"
        #print images.extract()

        items = []
        item = EbayScraperItem()
#        title = titles.select("text()").extract()
#        price = price.select("text()").extract()
        stock = stock.select("text()").extract()
        #title = title[1:-1]     # Remove quots
        item["title"] = str(titles).strip()
        item["price"] = price
        item["stock"] = stock
        formated_desc = ""
        for desc in description:
            formated_desc += str(desc.select("text()").extract())

        item["description"] = formated_desc
        item["images"] = images.select("@src").extract()
        items.append(item)
        return items
