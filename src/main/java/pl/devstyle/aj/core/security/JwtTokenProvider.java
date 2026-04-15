package pl.devstyle.aj.core.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Component
public class JwtTokenProvider {

    private final SecretKey secretKey;
    private final long expirationMs;

    public JwtTokenProvider(@Value("${app.jwt.secret}") String secret,
                            @Value("${app.jwt.expiration-ms}") long expirationMs) {
        this.secretKey = Keys.hmacShaKeyFor(Base64.getDecoder().decode(secret));
        this.expirationMs = expirationMs;
    }

    public String generateToken(String username, Set<String> permissions) {
        return generateTokenWithExpiration(username, permissions, expirationMs);
    }

    public String generateTokenWithExpiration(String username, Set<String> permissions, long expirationMs) {
        var now = new Date();
        var expiry = new Date(now.getTime() + expirationMs);
        return Jwts.builder()
                .subject(username)
                .claim("permissions", List.copyOf(permissions))
                .issuedAt(now)
                .expiration(expiry)
                .signWith(secretKey)
                .compact();
    }

    public record ParsedToken(String username, Set<String> permissions) {}

    /**
     * Parse and validate a JWT token in a single operation, avoiding multiple signature verifications.
     *
     * @return parsed token data, or empty if the token is invalid/expired
     */
    @SuppressWarnings("unchecked")
    public Optional<ParsedToken> parseToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            String username = claims.getSubject();
            List<String> permissions = claims.get("permissions", List.class);
            return Optional.of(new ParsedToken(username, Set.copyOf(permissions)));
        } catch (JwtException | IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    public String getUsernameFromToken(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
    }

    @SuppressWarnings("unchecked")
    public Set<String> getPermissionsFromToken(String token) {
        var claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        List<String> permissions = claims.get("permissions", List.class);
        return Set.copyOf(permissions);
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
