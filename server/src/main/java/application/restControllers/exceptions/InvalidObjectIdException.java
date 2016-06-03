package application.restControllers.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Created by matan on 10/05/2016.
 */

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class InvalidObjectIdException extends RuntimeException {

    public InvalidObjectIdException(String objectId) {
        super("" + objectId + " is not a valid id");
    }
}
