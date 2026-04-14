package pl.devstyle.aj.core.oauth2;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
@Slf4j
public class RefreshTokenService {

    private static final long TOKEN_EXPIRATION_SECONDS = 86400; // 24 hours
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final ConcurrentHashMap<String, RefreshTokenData> refreshTokens = new ConcurrentHashMap<>();

    public String issueToken(String username, Set<String> permissions, String scope) {
        var token = generateToken();
        var data = new RefreshTokenData(username, permissions, scope, Instant.now());
        refreshTokens.put(token, data);
        log.debug("Issued refresh token for user: {}", username);
        return token;
    }

    public Optional<RotationResult> consumeAndRotate(String token) {
        var data = refreshTokens.remove(token);
        if (data == null) {
            log.warn("Refresh token consumption failed | reason=Token not found or already used");
            return Optional.empty();
        }

        if (data.createdAt().plusSeconds(TOKEN_EXPIRATION_SECONDS).isBefore(Instant.now())) {
            log.warn("Refresh token consumption failed | user={} | reason=Token expired", data.username());
            return Optional.empty();
        }

        // Issue new refresh token (rotation)
        var newToken = generateToken();
        var newData = new RefreshTokenData(data.username(), data.permissions(), data.scope(), Instant.now());
        refreshTokens.put(newToken, newData);

        log.debug("Rotated refresh token for user: {}", data.username());
        return Optional.of(new RotationResult(newToken, data));
    }

    @Scheduled(fixedRate = 1_800_000) // every 30 minutes
    void cleanupExpiredTokens() {
        var now = Instant.now();
        int removed = 0;
        var iterator = refreshTokens.entrySet().iterator();
        while (iterator.hasNext()) {
            var entry = iterator.next();
            if (entry.getValue().createdAt().plusSeconds(TOKEN_EXPIRATION_SECONDS).isBefore(now)) {
                iterator.remove();
                removed++;
            }
        }
        if (removed > 0) {
            log.debug("Cleaned up {} expired refresh tokens", removed);
        }
    }

    private String generateToken() {
        var bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public record RefreshTokenData(
            String username,
            Set<String> permissions,
            String scope,
            Instant createdAt
    ) {}

    public record RotationResult(
            String newToken,
            RefreshTokenData originalData
    ) {}
}
