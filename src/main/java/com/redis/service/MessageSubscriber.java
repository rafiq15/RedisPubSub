package com.redis.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
public class MessageSubscriber implements MessageListener {

    private final SimpMessagingTemplate messagingTemplate;

    @Autowired
    public MessageSubscriber(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        String receivedMessage = new String(message.getBody());
        System.out.println("Received message: " + receivedMessage);
        // Send message to WebSocket topic
        messagingTemplate.convertAndSend("/topic/messages", receivedMessage);
    }
}