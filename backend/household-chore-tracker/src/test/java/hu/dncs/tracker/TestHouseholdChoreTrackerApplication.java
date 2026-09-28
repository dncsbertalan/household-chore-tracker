package hu.dncs.tracker;

import org.springframework.boot.SpringApplication;

public class TestHouseholdChoreTrackerApplication {

    public static void main(String[] args) {
        SpringApplication.from(HouseholdChoreTrackerApplication::main).with(TestcontainersConfiguration.class).run(args);
    }

}
