package pl.devstyle.aj.core.oauth2;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
@Slf4j
public class AuthorizationCodeService {

    private static final long CODE_EXPIRATION_SECONDS = 600; // 10 minutes

    private final ConcurrentHashMap<String, AuthorizationCodeData> authorizationCodes = new ConcurrentHashMap<>();

    public void storeAuthorizationCode(String code, String clientId, String redirectUri, String scope,
                                       String codeChallenge, String codeChallengeMethod,
                                       String username, Set<String> permissions) {
        var data = new AuthorizationCodeData(
                clientId, redirectUri, scope, codeChallenge, codeChallengeMethod,
                username, permissions, Instant.now()
        );
        authorizationCodes.put(code, data);
        log.debug("Stored authorization code for client: {} with TTL: {}s", clientId, CODE_EXPIRATION_SECONDS);
    }

    public Optional<AuthorizationCodeData> consumeAuthorizationCode(String code) {
        var data = authorizationCodes.remove(code);
        if (data == null) {
            log.warn("Authorization code consumption failed | reason=Code not found or already used");
            return Optional.empty();
        }

        if (data.createdAt().plusSeconds(CODE_EXPIRATION_SECONDS).isBefore(Instant.now())) {
            log.warn("Authorization code consumption failed | client_id={} | reason=Code expired", data.clientId());
            return Optional.empty();
        }

        log.debug("Consumed authorization code for client: {}", data.clientId());
        return Optional.of(data);
    }

    @Scheduled(fixedRate = 300_000) // every 5 minutes
    void cleanupExpiredCodes() {
        var now = Instant.now();
        int removed = 0;
        var iterator = authorizationCodes.entrySet().iterator();
        while (iterator.hasNext()) {
            var entry = iterator.next();
            if (entry.getValue().createdAt().plusSeconds(CODE_EXPIRATION_SECONDS).isBefore(now)) {
                iterator.remove();
                removed++;
            }
        }
        if (removed > 0) {
            log.debug("Cleaned up {} expired authorization codes", removed);
        }
    }

    public record AuthorizationCodeData(
            String clientId,
            String redirectUri,
            String scope,
            String codeChallenge,
            String codeChallengeMethod,
            String username,
            Set<String> permissions,
            Instant createdAt
    ) {}
}
