package pl.devstyle.aj;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import org.springframework.security.test.context.support.WithMockUser;

@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@WithMockUser(username = "test-admin", authorities = {"PERMISSION_READ", "PERMISSION_EDIT", "PERMISSION_PLUGIN_MANAGEMENT"})
public @interface WithMockAdminUser {
}
