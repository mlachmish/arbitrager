#!/bin/bash
function myprog() {
cd /Users/matan/Developer/arbitrager/scraper/ebay_scraper/ebay_scraper
scrapy parse $1 -c getProduct -o items.json -t json
}
