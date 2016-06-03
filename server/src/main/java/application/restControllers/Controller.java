package application.restControllers;

import application.model.EbayClient;
import application.model.Product;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

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

    @RequestMapping(path = "/publish" ,method = RequestMethod.POST, produces = MediaType.APPLICATION_JSON_VALUE)
    public void publish(@RequestBody PublishRequestBody publishRequestBody) {
        EbayClient.addItem(publishRequestBody.price, publishRequestBody.description, publishRequestBody.name, publishRequestBody.imageURL);
    }

    private static final class PublishRequestBody {
        private String name;
        private String price;
        private String description;
        private String imageURL;

        @JsonCreator
        public PublishRequestBody(@JsonProperty("name")String name,
                                     @JsonProperty("price")String price,
                                     @JsonProperty("newPrice")String newPrice,
                                     @JsonProperty("inStock")String inStock,
                                     @JsonProperty("description")String description,
                                     @JsonProperty("imageURL")String imageURL) {
            this.name = name;
            this.price = price;
            this.description = description;
            this.imageURL = imageURL;
        }
    }
}
