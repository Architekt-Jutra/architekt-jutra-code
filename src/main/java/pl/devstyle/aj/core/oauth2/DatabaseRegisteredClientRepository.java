package pl.devstyle.aj.core.oauth2;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
@Slf4j
public class DatabaseRegisteredClientRepository implements RegisteredClientRepository {

    private final RegisteredClientJpaRepository jpaRepository;

    @Override
    public void save(RegisteredClient registeredClient) {
        var entity = toEntity(registeredClient);
        jpaRepository.save(entity);
        log.info("Saved OAuth2 registered client | client_id={} | client_name={}",
                registeredClient.getClientId(), registeredClient.getClientName());
    }

    @Override
    public RegisteredClient findById(String id) {
        return jpaRepository.findById(UUID.fromString(id))
                .map(this::toRegisteredClient)
                .orElse(null);
    }

    @Override
    public RegisteredClient findByClientId(String clientId) {
        return jpaRepository.findByClientId(clientId)
                .map(this::toRegisteredClient)
                .orElse(null);
    }

    private RegisteredClientEntity toEntity(RegisteredClient client) {
        var entity = new RegisteredClientEntity();
        entity.setId(UUID.fromString(client.getId()));
        entity.setClientId(client.getClientId());
        entity.setClientIdIssuedAt(client.getClientIdIssuedAt() != null ? client.getClientIdIssuedAt() : Instant.now());
        entity.setClientSecret(client.getClientSecret());
        entity.setClientSecretExpiresAt(client.getClientSecretExpiresAt());
        entity.setClientName(client.getClientName());

        entity.setClientAuthenticationMethods(
                client.getClientAuthenticationMethods().stream()
                        .map(ClientAuthenticationMethod::getValue)
                        .collect(Collectors.toList())
        );

        entity.setAuthorizationGrantTypes(
                client.getAuthorizationGrantTypes().stream()
                        .map(AuthorizationGrantType::getValue)
                        .collect(Collectors.toList())
        );

        if (client.getRedirectUris() != null && !client.getRedirectUris().isEmpty()) {
            entity.setRedirectUris(new ArrayList<>(client.getRedirectUris()));
        }

        entity.setScopes(new ArrayList<>(client.getScopes()));

        return entity;
    }

    private RegisteredClient toRegisteredClient(RegisteredClientEntity entity) {
        Set<String> clientAuthMethods = new HashSet<>(entity.getClientAuthenticationMethods());
        Set<String> grantTypes = new HashSet<>(entity.getAuthorizationGrantTypes());
        Set<String> redirectUris = entity.getRedirectUris() != null
                ? new HashSet<>(entity.getRedirectUris())
                : Set.of();
        Set<String> scopes = new HashSet<>(entity.getScopes());

        var builder = RegisteredClient.withId(entity.getId().toString())
                .clientId(entity.getClientId())
                .clientIdIssuedAt(entity.getClientIdIssuedAt())
                .clientSecret(entity.getClientSecret())
                .clientSecretExpiresAt(entity.getClientSecretExpiresAt())
                .clientName(entity.getClientName());

        clientAuthMethods.forEach(method ->
                builder.clientAuthenticationMethod(new ClientAuthenticationMethod(method)));

        grantTypes.forEach(grantType ->
                builder.authorizationGrantType(new AuthorizationGrantType(grantType)));

        redirectUris.forEach(builder::redirectUri);
        scopes.forEach(builder::scope);

        return builder.build();
    }
}
