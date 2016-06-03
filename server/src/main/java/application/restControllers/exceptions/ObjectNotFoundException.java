package application.restControllers.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Created by matan on 13/05/2016.
 */

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ObjectNotFoundException extends RuntimeException {

    public ObjectNotFoundException(String className, String key) {
        super("could not find object of class: '" + className + "' with key: '" + key + "'.");
    }

}