package pl.devstyle.aj.core.oauth2;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record OAuth2ErrorResponse(
        String error,
        @JsonProperty("error_description") String errorDescription,
        @JsonProperty("error_uri") String errorUri
) {
    public static OAuth2ErrorResponse of(OAuth2Error error, String customDescription) {
        return new OAuth2ErrorResponse(
                error.getError(),
                customDescription != null ? customDescription : error.getDescription(),
                null
        );
    }

    public static OAuth2ErrorResponse of(OAuth2Error error) {
        return of(error, null);
    }
}
