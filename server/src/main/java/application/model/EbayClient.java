package application.model;

import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.WebResource;

import javax.ws.rs.core.MediaType;
import java.util.logging.Level;
import java.util.logging.Logger;


/**
 * Created by matan,
 * On 03/06/2016.
 */
public class EbayClient {
    private static final Logger log = Logger.getLogger( EbayClient.class.getName() );

    private static String SERVERURL = "https://api.sandbox.ebay.com/ws/api.dll";
    private static String USERTOKEN = "AgAAAA**AQAAAA**aAAAAA**wV1RVw**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wFk4GgDpeCpQydj6x9nY+seQ**stUDAA**AAMAAA**DcloQKF6/LdYyic8UJNxD0wU3kYF57/4J/WcO8bmqyMc9DY7Kut+xCIWD2UA1Zu8QOp4s+pNkrSfrkP8609kiAQ96Ttk0wHvk8iSuDK0CCaPsFEK8XuWSAoyIIki67Sa7MP85GqD+AGNMRbHFwG5bg8R52c1bWAT4ZoiHvE6ihwqZkrC29mwBoaxIarccsqLVAmWfyhLTMtWNklnj5ndrIqggevDRDQ3r5qsqZkFZ7/qNCWUQluwMbUJvG+H5nYjxmA/0hQm1aUH2XWsq3THecFP2rTlMipapq95jHYAdZ02T0Qd4nGJ/AbJe3yQFN41/5U8uXnfBReHS1PxybBuzVIWwBWs170NeCWZjXzGDLzL6niLIyquzusAEbNZCQZSEmn2TpF0VY4EjoQE/v85bDDlw0jyWW6UMIHAbcQ+BwM+UyB87oCemuXtn3vetdRliGM/bhQiTc7E8CSEytDtyIjUH3xPnYik4yJ4T7sH6/0tHyGzUOLGNyPgv+1WjAMltdBilSpvjcbZZD9iJBy1uF3wzr+HAehoHO+/PhjPpO9/STLF4bJ0oXZJVnCaTV3N9LZ3HAX+CtqrEL2oPr2E8LwBoO137hVkqB60LVoL0eK7u8geegw7FYvdV6R+i5TwHB4POzYMYi8rc2Rt2TSpyKNwiZ5Yg79EmW5N0kjkC97nzF/DBRHJ69MFW9lGHyIhNPkc4Z/65mgiK0P2bvC6zfA8PH+Qv6JDppDGKu9pWi4upXhMIDoHx90bvDIt2YAK";
    private static String XML = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
            "<AddItemRequest xmlns=\"urn:ebay:apis:eBLBaseComponents\">\n" +
            "  <RequesterCredentials>\n" +
            "    <eBayAuthToken>$TOKEN</eBayAuthToken>\n" +
            "  </RequesterCredentials>\n" +
            "  <Item>\n" +
            "    <StartPrice>$PRICE</StartPrice>\n" +
            "    <Country>US</Country>\n" +
            "    <Currency>USD</Currency>\n" +
            "    <DispatchTimeMax>3</DispatchTimeMax>\n" +
            "    <ListingDuration>Days_7</ListingDuration>\n" +
            "    <ListingType>FixedPriceItem</ListingType>\n" +
            "    <PaymentMethods>PayPal</PaymentMethods>\n" +
            "    <PayPalEmailAddress>megaonlinemerchant@gmail.com</PayPalEmailAddress>\n" +
            "    <PostalCode>95125</PostalCode>\n" +
            "    <Title>$TITLE</Title>\n" +
            "    <Description>$DESCRIPTION</Description>\n" +
            "    <PictureDetails>\n" +
            "      <PictureURL>$IMAGE_URL</PictureURL>\n" +
            "    </PictureDetails>\n" +
            "    <PrimaryCategory>\n" +
            "      <CategoryID>60437</CategoryID>\n" +
            "    </PrimaryCategory>\n" +
            "    <ProductListingDetails>\n" +
            "      <UPC>885909298594</UPC>\n" +
            "      <IncludePrefilledItemInformation>true</IncludePrefilledItemInformation>\n" +
            "      <IncludeStockPhotoURL>true</IncludeStockPhotoURL>\n" +
            "    </ProductListingDetails>\n" +
            "    <Quantity>6</Quantity>\n" +
            "    <ReturnPolicy>\n" +
            "      <ReturnsAcceptedOption>ReturnsAccepted</ReturnsAcceptedOption>\n" +
            "      <RefundOption>MoneyBack</RefundOption>\n" +
            "      <ReturnsWithinOption>Days_30</ReturnsWithinOption>\n" +
            "      <Description>If not satisfied, return the item for refund.</Description>\n" +
            "    </ReturnPolicy>\n" +
            "    <ShippingDetails>\n" +
            "      <ShippingServiceOptions>\n" +
            "        <ShippingServicePriority>1</ShippingServicePriority>\n" +
            "        <ShippingService>UPSGround</ShippingService>\n" +
            "        <ShippingServiceCost>0.00</ShippingServiceCost>\n" +
            "        <ShippingServiceAdditionalCost>0.00</ShippingServiceAdditionalCost>\n" +
            "      </ShippingServiceOptions>\n" +
            "    </ShippingDetails>\n" +
            "    <Site>US</Site>\n" +
            "  </Item>\n" +
            "</AddItemRequest>";

    public static void addItem(String price, String description, String title, String imageURL) {
        Client client = Client.create();
        WebResource webResource = client.resource(SERVERURL);

        String requestXML = XML.replace("$TOKEN", USERTOKEN).replace("$PRICE", price).replace("$DESCRIPTION", description).replace("$TITLE", title).replace("$IMAGE_URL", imageURL);

        ClientResponse response = webResource.type(MediaType.APPLICATION_XML)
                .header("X-EBAY-API-COMPATIBILITY-LEVEL", "383")
                .header("X-EBAY-API-CALL-NAME", "AddItem")
                .header("X-EBAY-API-SITEID", "0")
                .post(ClientResponse.class, requestXML);

        log.log(Level.ALL, "Response for add item: " + response.getStatus() + " " + response);
    }
}
