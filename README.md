# Ticketing
A PET project focused on experimenting with microservices architecture and exploring the **Clan Architecture** design pattern. 

To set-up locally run next script
```shell
curl -o init.sh  https://raw.githubusercontent.com/dzhuryn97/ticketing-infra/main/init.sh && chmod +x init.sh && ./init.sh
```

## Services Overview

### Auth
Handles user management, authentication via credentials, and JWT token generation.

### Events
Manages event categories, events, and ticket types.

### Tickets
Facilitates the sale of tickets.

### Attendance
Provides a check-in feature for event attendance. Planned future functionality includes gathering attendance statistics.


## Patterns

### Communication style
The project user asynchronous communication between services, utilizing **RabbitMQ** and **Symfony Messenger**.


### Next improvement:
* Try package phpsagas/orchestrator
* Improve ci/cd
* Implement distributed logging and tracing
* Try Direct communication, gRPC, Circuit Breaker pattern
* Divide feature tests from integration tests