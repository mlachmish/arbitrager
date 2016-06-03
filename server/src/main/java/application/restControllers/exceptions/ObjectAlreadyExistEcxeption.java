package application.restControllers.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Created by matan on 22/05/2016.
 */

@ResponseStatus(HttpStatus.CONFLICT)
public class ObjectAlreadyExistEcxeption extends RuntimeException {

    public ObjectAlreadyExistEcxeption(String className, String key) {
        super("Object already exist of class: '" + className + "' with key: '" + key + "'.");
    }
}
