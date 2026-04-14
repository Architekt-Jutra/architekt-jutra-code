package pl.devstyle.aj.mcp.exception;

/**
 * Exception thrown by MCP tool operations.
 * Used to wrap backend API errors into structured MCP error responses.
 */
public class McpToolException extends RuntimeException {

    private final ErrorType errorType;

    public McpToolException(ErrorType errorType, String message) {
        super(message);
        this.errorType = errorType;
    }

    public McpToolException(ErrorType errorType, String message, Throwable cause) {
        super(message, cause);
        this.errorType = errorType;
    }

    public ErrorType getErrorType() {
        return errorType;
    }

    public static McpToolException validationError(String message) {
        return new McpToolException(ErrorType.VALIDATION, message);
    }

    public static McpToolException notFound(String message) {
        return new McpToolException(ErrorType.NOT_FOUND, message);
    }

    public static McpToolException apiError(String message) {
        return new McpToolException(ErrorType.API_ERROR, message);
    }

    public static McpToolException apiError(String message, Throwable cause) {
        return new McpToolException(ErrorType.API_ERROR, message, cause);
    }

    public static McpToolException invalidCriteria(String details, String suggestion) {
        return new McpToolException(ErrorType.VALIDATION,
                String.format("Invalid criteria: %s. %s", details, suggestion));
    }

    public enum ErrorType {
        VALIDATION,
        NOT_FOUND,
        API_ERROR
    }
}
