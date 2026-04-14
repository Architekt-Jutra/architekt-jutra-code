package pl.devstyle.aj.core.oauth2;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface RegisteredClientJpaRepository extends JpaRepository<RegisteredClientEntity, UUID> {

    Optional<RegisteredClientEntity> findByClientId(String clientId);
}
