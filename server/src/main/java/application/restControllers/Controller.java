package application.restControllers;

import application.model.Product;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;


import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.logging.Logger;

/**
 * Created by matan on 13/05/2016.
 */

@RestController
public class Controller {

    private static final Logger log = Logger.getLogger( Controller.class.getName() );

    //REST ENDPOINTS
    @RequestMapping(path = "/product" ,method = RequestMethod.GET, produces = MediaType.APPLICATION_JSON_VALUE)
    public Product getProduct(@RequestHeader String amazonURL) {
        return Product.getProductFromURL(amazonURL);
    }
}
