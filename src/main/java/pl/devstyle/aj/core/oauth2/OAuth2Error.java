package pl.devstyle.aj.core.oauth2;

/**
 * Standard OAuth2 error codes as defined in RFC 6749.
 */
public enum OAuth2Error {
    INVALID_REQUEST("invalid_request", "The request is missing a required parameter, includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed"),
    UNAUTHORIZED_CLIENT("unauthorized_client", "The client is not authorized to request an authorization code using this method"),
    ACCESS_DENIED("access_denied", "The resource owner or authorization server denied the request"),
    UNSUPPORTED_RESPONSE_TYPE("unsupported_response_type", "The authorization server does not support obtaining an authorization code using this method"),
    INVALID_SCOPE("invalid_scope", "The requested scope is invalid, unknown, or malformed"),
    SERVER_ERROR("server_error", "The authorization server encountered an unexpected condition that prevented it from fulfilling the request"),

    INVALID_CLIENT("invalid_client", "Client authentication failed"),
    INVALID_GRANT("invalid_grant", "The provided authorization grant or refresh token is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client"),
    UNSUPPORTED_GRANT_TYPE("unsupported_grant_type", "The authorization grant type is not supported by the authorization server"),

    INVALID_CLIENT_METADATA("invalid_client_metadata", "The value of one or more client metadata fields is invalid");

    private final String error;
    private final String description;

    OAuth2Error(String error, String description) {
        this.error = error;
        this.description = description;
    }

    public String getError() {
        return error;
    }

    public String getDescription() {
        return description;
    }
}
