// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/grpc;
import ballerina/log;
import ballerinax/googleapis.gmail as gmail;

listener grpc:Listener ep = new (9097);

type GmailConfig record {|
    string refreshToken;
    string clientId;
    string clientSecret;
|};

configurable GmailConfig gmail = ?;

gmail:ConnectionConfig gmailConfig = {
    auth: {
        refreshUrl: gmail:REFRESH_URL,
        refreshToken: gmail.refreshToken,
        clientId: gmail.clientId,
        clientSecret: gmail.clientSecret
    }
};

final gmail:Client gmailClient = check new (gmailConfig);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "EmailService" on ep {

    isolated remote function SendOrderConfirmation(SendOrderConfirmationRequest value) returns Empty|error {

        OrderResult orderRes = value.'order;
        string htmlBody = self.getConfirmationHtml(orderRes).toString();
        gmail:MessageRequest messageRequest = {
            recipient: value.email,
            subject: "Order Confirmation",
            messageBody: htmlBody,
            contentType: gmail:TEXT_HTML
        };

        gmail:Message|error sendMessageResponse = gmailClient->sendMessage(messageRequest);

        if sendMessageResponse is gmail:Message {
            log:printInfo("Sent Message ID: " + sendMessageResponse.id);
            log:printInfo("Sent Thread ID: " + sendMessageResponse.threadId);
        } else {
            log:printError("Error sending confirmation mail ", 'error = sendMessageResponse);
        }
        return {};
    }

    isolated function getConfirmationHtml(OrderResult res) returns xml {
        string fontUrl = "https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,400;0,700;1,400;1,700&display=swap";

        xml items = xml `<tr>
          <th>Item No.</th>
          <th>Quantity</th> 
          <th>Price</th>
        </tr>`;

        foreach OrderItem item in res.items {
            xml content = xml `<tr>
            <td>#${item.item.product_id}</td>
            <td>${item.item.quantity}</td> 
            <td>${item.cost.units}.${item.cost.nanos / 10000000} ${item.cost.currency_code}</td>
            </tr>`;
            items = items + content;
        }

        xml body = xml `<body>
        <h2>Your Order Confirmation</h2>
        <p>Thanks for shopping with us!</p>
        <h3>Order ID</h3>
        <p>#${res.order_id}</p>
        <h3>Shipping</h3>
        <p>#${res.shipping_tracking_id}</p>
        <p>${res.shipping_cost.units}.${res.shipping_cost.nanos / 10000000} ${res.shipping_cost.currency_code}</p>
        <p>${res.shipping_address.street_address}, ${res.shipping_address.city}, ${res.shipping_address.country} ${res.shipping_address.zip_code}</p>
        <h3>Items</h3>
        <table style="width:100%">
            ${items}
        </table>
        </body>
        `;

        xml page = xml `
        <html>
        <head>
            <title>Your Order Confirmation</title>
            <link href="${fontUrl}" rel="stylesheet"></link>
        </head>
        <style>
            body{
            font-family: 'DM Sans', sans-serif;
            }
        </style>
            ${body}
        </html>`;

        return page;
    }
}

