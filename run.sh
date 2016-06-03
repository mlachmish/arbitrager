#!/bin/bash
function myprog() {
cd /Users/alachmish/Documents/arbitrager/arbitrager/scraper/ebay_scraper/
scrapy parse $1 -c getProduct -o items.json -t json
}