import ballerina/test;

@test:Config {}
function cartTest() returns error? {
    CartServiceClient ep = check new ("http://localhost:9092");
    //Add Cart
    AddItemRequest item1 = {user_id: "1", item: {product_id: "11", quantity: 1}};
    _ = check ep->AddItem(item1);

    GetCartRequest user1 = {user_id: "1"};
    Cart cart = check ep->GetCart(user1);
    test:assertEquals(cart.items.length(), 1);

    //Add quantity
    AddItemRequest item2 = {user_id: "1", item: {product_id: "11", quantity: 2}};
    _ = check ep->AddItem(item2);
    Cart cart1 = check ep->GetCart(user1);
    test:assertEquals(cart1.items[0].quantity, 3);

    //Add item
    AddItemRequest item3 = {user_id: "1", item: {product_id: "12", quantity: 2}};
    _ = check ep->AddItem(item3);
    Cart cart2 = check ep->GetCart(user1);
    test:assertEquals(cart2.items.length(), 2);
}
