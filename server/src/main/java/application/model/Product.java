package application.model;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.Serializable;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Created by matan on 13/05/2016.
 */

public class Product implements Serializable {
    private static final Logger log = Logger.getLogger( Product.class.getName() );

    private String name;
    private String price;
    private Boolean inStock;
    private String description;
    private String imageURL;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPrice() {
        return price;
    }

    public void setPrice(String price) {
        this.price = price;
    }

    public Boolean getInStock() {
        return inStock;
    }

    public void setInStock(Boolean inStock) {
        this.inStock = inStock;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImageURL() {
        return imageURL;
    }

    public void setImageURL(String imageURL) {
        this.imageURL = imageURL;
    }

    public Product(String name, String price, Boolean inStock, String description, String imageURL) {
        this.name = name;
        this.price = price;
        this.inStock = inStock;
        this.description = description;
        this.imageURL = imageURL;
    }

    public static Product getProductFromURL(String urlString) {
        try {
            Document doc = Jsoup.connect(urlString).get();
            String name = doc.select("span#productTitle").text();
            String price = doc.select("span#priceblock_ourprice").text().substring(1);
            Boolean inStock = Objects.equals(doc.select("div#availability span").text(), "In Stock.");
            String description = doc.select("div#feature-bullets").text();
            String imageUrl = doc.select("img#landingImage").attr("src");

            return new Product(name, price, inStock, description, imageUrl);
        } catch (Exception e) {
            log.log(Level.ALL, "Error scraping: " + e);
            return null;
        }
    }
}