package edu.man.kafka.producer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;

@Slf4j
@SpringBootApplication
public class MainApplication {
    public static void main(String[] args) {
        log.info("Hello, main application is started");
        SpringApplication.run(MainApplication.class, args);
    }

    @EventListener(ContextRefreshedEvent.class)
    public void runAfterStartup() {
        log.info("Running after application startup...");
    }
}