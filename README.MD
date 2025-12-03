
# Step(1) : Run Mongo db into the machine
```bash
docker compose -f docker-compose-dev.yaml up -d kstream-prod-mongo
```

# Step(2) : Exec mongosh
```bash
docker-compose -f docker-compose-dev.yaml exec kstream-prod-mongo mongosh "mongodb://root:password@localhost:27017" --authenticationDatabase admin
```
mongosh "mongodb://root:password@localhost:27017/inventorydb?authSource=admin"
```javascript
db.variety.find({type:'phone'}).pretty();
```
Note: use mongodb://root:password@mongo-net:27017/inventorydb?authSource=admin for 


mongodb://root:password@localhost:27017/inventorydb?authSource=admin

# Step(3) : Clean Java Project
```bash
mvn dependency:purge-local-repository -DreResolve=false
mvn clean install -DskipTests
```

# Step(4) : Start Java Application
```bash
#mvn compile exec:java -Dexec.mainClass="edu.man.kafka.producer.MainApplication" -Dexec.cleanupDaemonThreads=false -Dspring.profiles.active=local

mvn -Dspring.profiles.active=local clean compile exec:java

mvn spring-boot:run
```

