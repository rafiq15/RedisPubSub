# Redis Pub/Sub WebSocket Example

This project demonstrates a simple messaging application using **Spring Boot**, **Redis Pub/Sub**, and **WebSocket** for real-time message delivery.

## Features

- Publish messages via a web form.
- Messages are sent to a Redis channel.
- Messages are broadcast to all connected clients using WebSocket (STOMP).
- Live message updates on the UI.

## Getting Started

### Prerequisites

- Java 17 or higher
- Gradle
- Redis server running on `localhost:6379`

### Running the Application

1. Start your Redis server.
2. Build and run the Spring Boot application:
   ./gradlew bootRun
3. Open [http://localhost:8445](http://localhost:8445) in your browser.

### Usage

- **Publish a Message:**  
  Enter a message in the form on the home page and submit.
- **View Live Messages:**  
  Click "View Live Messages" to see messages appear in real time as they are published.

## Configuration

- Redis connection settings are in `src/main/resources/application.properties`.
- WebSocket endpoint: `/ws`
- STOMP topic: `/topic/messages`
- Redis channel: `messageQueue`

## File Structure

- `src/main/java/com/redis/config/RedisConfig.java` — Redis and topic configuration.
- `src/main/resources/templates/index.html` — Message publishing form.
- `src/main/resources/templates/messages.html` — Live message view.

## Troubleshooting

- If you see unreadable characters in received messages, ensure `RedisTemplate` uses `StringRedisSerializer` for all serializers (already configured in this project).
- Make sure Redis is running and accessible at the configured host and port.

## License

This project is for educational purposes. All code is provided AI-generated.
