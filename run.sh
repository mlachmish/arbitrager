#!/bin/bash
cd scraper/ebay_scraper/ebay_scraper/
scrapy parse $1 -c getProduct 
