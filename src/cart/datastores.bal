public type DataStore object {
    isolated function add(string userId, string productId, int quantity);

    isolated function emptyCart(string userId);

    isolated function getCart(string userId) returns Cart;
};

public isolated class InMemoryStore {
    *DataStore;
    private map<Cart> store = {};

    isolated function add(string userId, string productId, int quantity) {
        lock {
            if (self.store.hasKey(userId)) {
                Cart existingCart = self.store.get(userId);
                CartItem[] existingItems = existingCart.items;
                CartItem[] matchedItem = from CartItem item in existingItems
                    where item.product_id == productId
                    limit 1
                    select item;
                if (matchedItem.length() == 1) {
                    //Update Quantitly
                    CartItem item = matchedItem[0];
                    if (item.product_id == productId) {
                        item.quantity = item.quantity + quantity;
                    }
                } else {
                    //Add item
                    CartItem newItem = {product_id: productId, quantity: quantity};
                    existingItems.push(newItem);
                }
            } else {
                //Add Cart
                Cart newItem = {
                    user_id: userId,
                    items: [{product_id: productId, quantity: quantity}]
                };
                self.store[userId] = newItem;
            }
        }
    }

    isolated function emptyCart(string userId) {
        lock {
            _ = self.store.remove(userId);
        }
    }

    isolated function getCart(string userId) returns Cart {
        lock {
            if (self.store.hasKey(userId)) {
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
}

public isolated class RedisStore {
    //TODO impl redis store
    *DataStore;
    private map<Cart> store = {};

    isolated function add(string userId, string productId, int quantity) {
    }

    isolated function emptyCart(string userId) {
        lock {
            _ = self.store.remove(userId);
        }
    }

    isolated function getCart(string userId) returns Cart {
        lock {
            return self.store.get(userId).cloneReadOnly();
        }
    }
}
