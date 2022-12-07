# Cart Service

The cart service manages all the details about the shopping card of the user. It implements the Repository pattern to have multiple implementations of DataStore. We have an in-memory data store and redis based data store in the application.

In the original c# implementation, the repository is defined using an interface. You can find the ballerina representation below. As you notice, the function body is not implemented. This forces the implementer to implement the body of the function.
```bal
public type DataStore object {
    isolated function add(string userId, string productId, int quantity);

    isolated function emptyCart(string userId);

    isolated function getCart(string userId) returns Cart;
};
```

Then we implement the DataStore using the concrete class `InMemoryStore` and `RedisStore` to provide the actual implementation of the Datastore.

```bal
public isolated class InMemoryStore {
    *DataStore;
    private map<Cart> store = {};

    isolated function add(string userId, string productId, int quantity) {
    }

    isolated function emptyCart(string userId) {
    }

    isolated function getCart(string userId) returns Cart {
    }
}
```

You could also observe that we use lock statements to ensure the concurrent safety.
```bal
isolated function getCart(string userId) returns Cart {
    lock {
        if self.store.hasKey(userId) {
            return self.store.get(userId).cloneReadOnly();
        }
        Cart newItem = {
            user_id: userId,
            items: []
        };
        self.store[userId] = newItem;
        return newItem.cloneReadOnly();
    }
}
```
And finally, we use the appropriate data store based on the config given by the user in the application initialization.

```bal
configurable string datastore = "";

service "CartService" on new grpc:Listener(9092) {
    private final DataStore store;

    function init() {
        if datastore == "redis" {
            log:printInfo("Redis datastore is selected");
            self.store = new RedisStore();
        } else {
            log:printInfo("In memory datastore is selected");
            self.store = new InMemoryStore();
        }
    }
}
```
