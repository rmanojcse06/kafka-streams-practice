// /mongo-init.js
// Initialize replica set
// rs_init.js content
print("? Starting mongodb-init.js");
//use admin;
// /mongo-init.js
// --- Admin DB authentication ---
db = db.getSiblingDB("admin");
print("? Starting mongodb replica set");
rs.initiate(
  {
    _id: "rs0",
    members: [
      { _id: 0, host: "localhost:27017" }
    ]
  }
);
print("? Waiting for 5s....");
sleep(5000); // wait for primary
print("? Creating inventorydba user");
appDb = db.getSiblingDB("rawsrcdb");
db.createUser({
  user: "inventorydba",
  pwd: "password",
  roles: [
    { role: "readWrite", db: "rawsrcdb" },
    { role: "dbAdmin", db: "rawsrcdb" }
  ]
});
print("✔ Created application user...");

// --- Application DB ---

print("✔ Creating database and collections...");

appDb.createCollection("rawdata");
print("✔ MongoDB initialization completed successfully.");

appDb.createCollection('inventory');
appDb.createCollection('brand');
appDb.brand.insertMany([
  { "type": "phone", "name": "Apple", "origin": "USA"},
  { "type": "phone", "name": "Samsung", "origin": "KOR"},
  { "type": "phone", "name": "Xiaomi", "origin": "CHN"},
  { "type": "phone", "name": "Huawei", "origin": "CHN"},
  { "type": "phone", "name": "OPPO", "origin": "CHN"},
  { "type": "phone", "name": "Vivo", "origin": "CHN"},
  { "type": "phone", "name": "OnePlus", "origin": "CHN"},
  { "type": "phone", "name": "Lenovo", "origin": "CHN"},
  { "type": "phone", "name": "Motorola", "origin": "USA"},
  { "type": "phone", "name": "Google (Pixel)", "origin": "USA"},
  { "type": "phone", "name": "Sony", "origin": "JPN"},
  { "type": "phone", "name": "LG", "origin": "KOR"},
  { "type": "phone", "name": "Nokia (HMD Global)", "origin": "FIN"},
  { "type": "phone", "name": "ASUS", "origin": "TWN"},
  { "type": "phone", "name": "HTC", "origin": "TWN"},
  { "type": "phone", "name": "Micromax", "origin": "IND"}
]);
appDb.createCollection('customer');
appDb.customer.insertMany([{"name":"manoj", "tel":"8122355373", "mail": "rmanojcse06@gmail.com"}]);


appDb.inventory.insertOne({ item: "phone", brand: "Apple", model: "iphone15", os: "ios-17", chipset: "A16 bionic", memory: { inbuild:["128GB","256GB","512GB"], external: null }, camera: { rear: { resolution: ["48MP", "12MP"], sensor: null }, front: { resolution: ["12MP"], sensor: null } }});