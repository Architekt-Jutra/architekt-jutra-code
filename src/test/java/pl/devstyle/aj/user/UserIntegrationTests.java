package pl.devstyle.aj.user;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;
import pl.devstyle.aj.TestcontainersConfiguration;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@Transactional
class UserIntegrationTests {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private jakarta.persistence.EntityManager entityManager;

    private User createAndSaveUser(String username, String passwordHash, Set<Permission> permissions) {
        var user = new User();
        user.setUsername(username);
        user.setPasswordHash(passwordHash);
        user.setPermissions(permissions);
        return userRepository.saveAndFlush(user);
    }

    @Test
    void saveUser_persistsUsernameAndPasswordHash() {
        var saved = createAndSaveUser("testuser", "$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012", Set.of());

        entityManager.clear();

        var found = userRepository.findById(saved.getId()).orElseThrow();
        assertThat(found.getUsername()).isEqualTo("testuser");
        assertThat(found.getPasswordHash()).isEqualTo("$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012");
        assertThat(found.getId()).isNotNull();
        assertThat(found.getCreatedAt()).isNotNull();
    }

    @Test
    void saveUser_duplicateUsername_throwsException() {
        createAndSaveUser("duplicate", "$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012", Set.of());

        var duplicate = new User();
        duplicate.setUsername("duplicate");
        duplicate.setPasswordHash("$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012");
        duplicate.setPermissions(Set.of());

        assertThatThrownBy(() -> userRepository.saveAndFlush(duplicate))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
    }

    @Test
    void saveUser_persistsPermissionsViaElementCollection() {
        var saved = createAndSaveUser("withperms", "$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012",
                Set.of(Permission.READ, Permission.EDIT));

        entityManager.clear();

        var found = userRepository.findById(saved.getId()).orElseThrow();
        assertThat(found.getPermissions()).containsExactlyInAnyOrder(Permission.READ, Permission.EDIT);
    }

    @Test
    void seedUsers_existWithCorrectPermissions() {
        var viewer = userRepository.findByUsername("viewer").orElseThrow();
        assertThat(viewer.getPermissions()).containsExactlyInAnyOrder(Permission.READ);

        var editor = userRepository.findByUsername("editor").orElseThrow();
        assertThat(editor.getPermissions()).containsExactlyInAnyOrder(Permission.READ, Permission.EDIT);

        var admin = userRepository.findByUsername("admin").orElseThrow();
        assertThat(admin.getPermissions()).containsExactlyInAnyOrder(Permission.READ, Permission.EDIT, Permission.PLUGIN_MANAGEMENT);
    }
}
