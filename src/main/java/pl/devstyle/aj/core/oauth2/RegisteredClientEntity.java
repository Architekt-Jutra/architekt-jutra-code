package pl.devstyle.aj.core.oauth2;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "oauth2_registered_client")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RegisteredClientEntity {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "client_id", nullable = false, unique = true)
    private String clientId;

    @Column(name = "client_id_issued_at", nullable = false)
    private Instant clientIdIssuedAt;

    @Column(name = "client_secret")
    private String clientSecret;

    @Column(name = "client_secret_expires_at")
    private Instant clientSecretExpiresAt;

    @Column(name = "client_name", nullable = false)
    private String clientName;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "client_authentication_methods", nullable = false, columnDefinition = "text[]")
    private List<String> clientAuthenticationMethods;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "authorization_grant_types", nullable = false, columnDefinition = "text[]")
    private List<String> authorizationGrantTypes;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "redirect_uris", columnDefinition = "text[]")
    private List<String> redirectUris;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "scopes", nullable = false, columnDefinition = "text[]")
    private List<String> scopes;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
