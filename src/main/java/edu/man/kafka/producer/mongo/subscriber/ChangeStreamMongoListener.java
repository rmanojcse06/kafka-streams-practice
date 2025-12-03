package edu.man.kafka.producer.mongo.subscriber;

import com.mongodb.reactivestreams.client.MongoClient;
import com.mongodb.reactivestreams.client.MongoClients;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.bson.Document;
import org.reactivestreams.Subscription;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.data.mongodb.core.ChangeStreamEvent;
import org.springframework.data.mongodb.core.ChangeStreamOptions;
import org.springframework.data.mongodb.core.ReactiveMongoTemplate;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

@Slf4j
@Service
public class ChangeStreamMongoListener {
    // Inject the bean via the constructor (best practice)
    private final ReactiveMongoTemplate reactiveMongoTemplate;

    // Use 'final' for immutable field and remove @Autowired
    public ChangeStreamMongoListener(ReactiveMongoTemplate reactiveMongoTemplate) {
        this.reactiveMongoTemplate = reactiveMongoTemplate;
    }

    @PostConstruct
    public void bootstrapListener() {

        /*
        ChangeStreamOptions options = ChangeStreamOptions.builder()
                .filter(
                        new Document("$match",
                                new Document("operationType",
                                        new Document("$in",
                                                java.util.Arrays.asList("insert", "update", "replace", "delete")
                                        )
                                )
                        )
                )
                .build();

                Flux<ChangeStreamEvent<Document>> changeStream = reactiveMongoTemplate.changeStream(
                       "inventorydb", "inventory", options, Document.class );
        */


        reactiveMongoTemplate.getMongoDatabase()
                .map(com.mongodb.reactivestreams.client.MongoDatabase::getName)
                .subscribe(dbName -> log.info("The connected database name is: {}", dbName));

        ChangeStreamOptions options = ChangeStreamOptions.builder()
                .returnFullDocumentOnUpdate()
                .build();

        reactiveMongoTemplate.changeStream("rawsrcdb", "rawdata", options, Document.class)
                .doOnError(err -> log.error("Change stream error", err))
                .retry()  // <--- IMPORTANT: automatic restart
                .subscribe(event -> {
                    Document rawData = event.getBody();
                    log.info("MongoDB rawData: {}", event.getBody());
        });
        log.info("✔ MongoDB change stream listener registered for inventory collection");
    }
}
