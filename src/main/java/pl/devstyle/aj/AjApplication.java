package pl.devstyle.aj;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class AjApplication {

	public static void main(String[] args) {
		SpringApplication.run(AjApplication.class, args);
	}

}
