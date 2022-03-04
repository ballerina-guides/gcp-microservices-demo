import ballerina/grpc;
import ballerina/uuid;
import ballerina/log;

listener grpc:Listener ep = new (9096);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "PaymentService" on ep {

    isolated remote function Charge(ChargeRequest value) returns ChargeResponse|error {
        CreditCardInfo creditCard = value.credit_card;
        CardValidator cardValidator = new (creditCard.credit_card_number, creditCard.credit_card_expiration_year, creditCard.credit_card_expiration_month);
        CardCompany|error cardValid = cardValidator.isValid();
        if cardValid is error {
            log:printError("Credit card is not valid", 'error = cardValid);
            return cardValid;
        }
        return {
            transaction_id: uuid:createType1AsString()
        };
    }
}

