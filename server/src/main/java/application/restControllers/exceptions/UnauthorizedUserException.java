package application.restControllers.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Created by matan on 20/05/2016.
 */
@ResponseStatus(HttpStatus.UNAUTHORIZED)
public class UnauthorizedUserException extends RuntimeException {

    public UnauthorizedUserException() {
        super("Unauthorized user");
    }

}