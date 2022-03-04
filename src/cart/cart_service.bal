import ballerina/grpc;
import ballerina/log;

configurable string redisHost = "";
configurable string redisPassword = "";
listener grpc:Listener ep = new (9092);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "CartService" on ep {
    private final DataStore store;

    function init() {
        if (redisHost == "" && redisPassword == "") {
            log:printInfo("In memory datastore used as redis conifg is not given");
            self.store = new InMemoryStore();
        } else {
            log:printInfo("Redis datastore is selected");
            self.store = new RedisStore();
        }
    }

    remote function AddItem(AddItemRequest value) returns Empty|error {
        lock {
            self.store.add(value.user_id, value.item.product_id, value.item.quantity);
        }
        return {};
    }
    remote function GetCart(GetCartRequest value) returns Cart|error {
        lock {
            Cart cart = self.store.getCart(value.user_id);
            return cart.cloneReadOnly();
        }
    }
    remote function EmptyCart(EmptyCartRequest value) returns Empty|error {
        lock {
            self.store.emptyCart(value.user_id);
        }
        return {};
    }
}

