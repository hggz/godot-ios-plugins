/*************************************************************************/
/*  in_app_store.mm                                                      */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2021 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "gamebridge.h"

#import <Foundation/Foundation.h>

#if VERSION_MAJOR == 4
typedef PackedStringArray GodotStringArray;
typedef PackedFloat32Array GodotFloatArray;
#else
typedef PoolStringArray GodotStringArray;
typedef PoolRealArray GodotFloatArray;
#endif

GameBridge *GameBridge::instance = NULL;

@interface GodotGameBridgeDelegate : NSObject

@property(nonatomic, strong) NSMutableArray *loadedEvents;
@property(nonatomic, strong) NSMutableArray *pendingEvents;

- (void)performRequestWithEventIDs:(NSSet *)eventIDs;
- (Error)performRequestWithEventID:(NSString *)eventID;
- (void)reset;

@end

@implementation GodotGameBridgeDelegate

- (instancetype)init {
	self = [super init];

	if (self) {
		[self godot_commonInit];
	}

	return self;
}

- (void)godot_commonInit {
	self.loadedEvents = [NSMutableArray new];
	self.pendingEvents = [NSMutableArray new];
}

- (void)performRequestWithEventIDs:(NSSet *)eventIDs {
    NSLog(@"perform request with event ids: %@", eventIDs);
    [self postNewNotificationWithDictionary: @{@"event_ids": eventIDs}];
}

- (Error)performRequestWithEventID:(NSString *)eventID {
    NSLog(@"perform request with event id: %@", eventID);
    [self postNewNotificationWithDictionary: @{@"event_id": eventID}];
	return OK;
}

- (void)postNewNotificationWithDictionary:(NSDictionary *)userInfo {
    NSLog(@"posting new notification from delegate");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GameBridgeNotificationDelegateSend"
                                                        object:nil
                                                      userInfo:userInfo];
}

- (void)reset {
	[self.loadedEvents removeAllObjects];
	[self.pendingEvents removeAllObjects];
}

/*
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	[self.pendingRequests removeObject:request];

	Dictionary ret;
	ret["type"] = "product_info";
	ret["result"] = "error";
	ret["error"] = String::utf8([error.localizedDescription UTF8String]);

	GameBridge::get_singleton()->_post_event(ret);
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	[self.pendingRequests removeObject:request];

	NSArray *products = response.products;
	[self.loadedProducts addObjectsFromArray:products];

	Dictionary ret;
	ret["type"] = "product_info";
	ret["result"] = "ok";
	GodotStringArray titles;
	GodotStringArray descriptions;
	GodotFloatArray prices;
	GodotStringArray ids;
	GodotStringArray localized_prices;
	GodotStringArray currency_codes;

	for (NSUInteger i = 0; i < [products count]; i++) {
		SKProduct *product = [products objectAtIndex:i];

		const char *str = [product.localizedTitle UTF8String];
		titles.push_back(String::utf8(str != NULL ? str : ""));

		str = [product.localizedDescription UTF8String];
		descriptions.push_back(String::utf8(str != NULL ? str : ""));
		prices.push_back([product.price doubleValue]);
		ids.push_back(String::utf8([product.productIdentifier UTF8String]));
		localized_prices.push_back(String::utf8([product.localizedPrice UTF8String]));
		currency_codes.push_back(String::utf8([[[product priceLocale] objectForKey:NSLocaleCurrencyCode] UTF8String]));
	}

	ret["titles"] = titles;
	ret["descriptions"] = descriptions;
	ret["prices"] = prices;
	ret["ids"] = ids;
	ret["localized_prices"] = localized_prices;
	ret["currency_codes"] = currency_codes;

	GodotStringArray invalid_ids;

	for (NSString *ipid in response.invalidProductIdentifiers) {
		invalid_ids.push_back(String::utf8([ipid UTF8String]));
	}

	ret["invalid_ids"] = invalid_ids;

	GameBridge::get_singleton()->_post_event(ret);
}
*/

@end

@interface GodotGameBridgeObserver : NSObject

@property(nonatomic, assign) BOOL shouldAutoFinishTransactions;
@property(nonatomic, strong) NSMutableDictionary *pendingTransactions;

- (void)finishTransactionWithEventID:(NSString *)eventID;
- (void)reset;

@end

@implementation GodotGameBridgeObserver

- (instancetype)init {
	self = [super init];

	if (self) {
		[self godot_commonInit];
	}

	return self;
}

- (void)godot_commonInit {
	self.pendingTransactions = [NSMutableDictionary new];
    [self setupNotificationObserver];
}

- (void)finishTransactionWithEventID:(NSString *)eventID {
    NSLog(@"finish transaction with event id: %@", eventID);
/*
	SKPaymentTransaction *transaction = self.pendingTransactions[productID];

	if (transaction) {
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	}

	self.pendingTransactions[productID] = nil;
*/
}

- (void)setupNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:@"GameBridgeNotificationReceive"
                                               object:nil];
}

- (void)postNewNotificationWithDictionary:(NSDictionary *)userInfo {
    NSLog(@"posting new notification from observer");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GameBridgeNotificationObserverSend"
                                                        object:nil
                                                      userInfo:userInfo];
}

- (void)handleNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *eventKey = userInfo[@"eventKey"];
    NSLog(@"Received userInfo: %@", userInfo);

    Dictionary ret;
    for (NSString *key in userInfo.allKeys) {
        id value = [userInfo objectForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            ret[String::utf8([key UTF8String])] = String::utf8([(NSString *)value UTF8String]);
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSArray *arrayValue = (NSArray *)value;
            GodotStringArray godotArray;
            for (NSString *item in arrayValue) {
                if ([item isKindOfClass:[NSString class]]) {
                    const char *str = [item UTF8String];
                    godotArray.push_back(String::utf8(str != NULL ? str : ""));
                }
            }
            ret[String::utf8([key UTF8String])] = godotArray;
        }
    }

    ret["type"] = String::utf8(eventKey != nil ? [eventKey UTF8String] : "");
    ret["result"] = "ok";
    GameBridge::get_singleton()->_post_event(ret);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reset {
	[self.pendingTransactions removeAllObjects];
}

/*
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	printf("transactions updated!\n");
	for (SKPaymentTransaction *transaction in transactions) {

		String pid;
		Dictionary ret;

		if (transaction.payment.productIdentifier.length > 0) {
			pid = String::utf8([transaction.payment.productIdentifier UTF8String]);
		} else {
			pid = "";
		}

		ret["product_id"] = pid;
		ret["type_code"] = (int)transaction.transactionState;

		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased: {
				printf("status purchased!\n");

				String transactionId = String::utf8([transaction.transactionIdentifier UTF8String]);
				GameBridge::get_singleton()->_record_purchase(pid);

				ret["type"] = "purchase";
				ret["result"] = "ok";

				ret["transaction_id"] = transactionId;

				NSData *receipt = nil;
				int sdk_version = [[[UIDevice currentDevice] systemVersion] intValue];

				NSBundle *bundle = [NSBundle mainBundle];
				// Get the transaction receipt file path location in the app bundle.
				NSURL *receiptFileURL = [bundle appStoreReceiptURL];

				// Read in the contents of the transaction file.
				receipt = [NSData dataWithContentsOfURL:receiptFileURL];

				NSString *receipt_to_send = nil;

				if (receipt != nil) {
					receipt_to_send = [receipt base64EncodedStringWithOptions:0];
				}
				Dictionary receipt_ret;
				receipt_ret["receipt"] = String::utf8(receipt_to_send != nil ? [receipt_to_send UTF8String] : "");
				receipt_ret["sdk"] = sdk_version;
				ret["receipt"] = receipt_ret;

				if (self.shouldAutoFinishTransactions) {
					[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				} else {
					self.pendingTransactions[transaction.payment.productIdentifier] = transaction;
				}
			} break;
			case SKPaymentTransactionStateFailed: {
				printf("status transaction failed!\n");
				ret["type"] = "purchase";
				ret["result"] = "error";
				ret["error"] = String::utf8([transaction.error.localizedDescription UTF8String]);
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
			} break;
			case SKPaymentTransactionStateRestored: {
				printf("status transaction restored!\n");
				String transactionId = String::utf8([transaction.transactionIdentifier UTF8String]);
				GameBridge::get_singleton()->_record_purchase(pid);
				ret["type"] = "restore";
				ret["result"] = "ok";
				ret["transaction_id"] = transactionId;

				NSData *receipt = nil;
				int sdk_version = [[[UIDevice currentDevice] systemVersion] intValue];

				NSBundle *bundle = [NSBundle mainBundle];
				// Get the transaction receipt file path location in the app bundle.
				NSURL *receiptFileURL = [bundle appStoreReceiptURL];

				// Read in the contents of the transaction file.
				receipt = [NSData dataWithContentsOfURL:receiptFileURL];

				NSString *receipt_to_send = nil;

				if (receipt != nil) {
					receipt_to_send = [receipt base64EncodedStringWithOptions:0];
				}
				Dictionary receipt_ret;
				receipt_ret["receipt"] = String::utf8(receipt_to_send != nil ? [receipt_to_send UTF8String] : "");
				receipt_ret["sdk"] = sdk_version;
				ret["receipt"] = receipt_ret;
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
			} break;
			case SKPaymentTransactionStatePurchasing: {
				ret["type"] = "purchase";
				ret["result"] = "progress";
			} break;
			case SKPaymentTransactionStateDeferred: {
				ret["type"] = "purchase";
				ret["result"] = "progress";
			} break;
			default: {
				ret["type"] = "purchase";
				ret["result"] = "unhandled";
				printf("Transaction is unhandled. Transaction state: %i!\n", (int)transaction.transactionState);
			} break;
		}

		GameBridge::get_singleton()->_post_event(ret);
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    Dictionary ret;
    ret["type"] = "restore";
    ret["result"] = "completed";
    GameBridge::get_singleton()->_post_event(ret);
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    Dictionary ret;
    ret["type"] = "restore";
    ret["result"] = "error";
    ret["error"] = String::utf8([error.localizedDescription UTF8String]);
    GameBridge::get_singleton()->_post_event(ret);
}
*/

@end

void GameBridge::_bind_methods() {
	ClassDB::bind_method(D_METHOD("request_gamebridge_info"), &GameBridge::request_gamebridge_info);
	ClassDB::bind_method(D_METHOD("gamebridge_refresh"), &GameBridge::gamebridge_refresh);
	ClassDB::bind_method(D_METHOD("gamebridge_invoke"), &GameBridge::gamebridge_invoke);

	ClassDB::bind_method(D_METHOD("get_pending_event_count"), &GameBridge::get_pending_event_count);
	ClassDB::bind_method(D_METHOD("pop_pending_event"), &GameBridge::pop_pending_event);
	ClassDB::bind_method(D_METHOD("gamebridge_transaction"), &GameBridge::gamebridge_transaction);
	ClassDB::bind_method(D_METHOD("set_auto_finish_transaction"), &GameBridge::set_auto_finish_transaction);
}

Error GameBridge::request_gamebridge_info(Dictionary p_params) {
	ERR_FAIL_COND_V(!p_params.has("event_ids"), ERR_INVALID_PARAMETER);

	GodotStringArray pids = p_params["event_ids"];
	printf("************ request event info! %i\n", pids.size());

	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:pids.size()];
	for (int i = 0; i < pids.size(); i++) {
		printf("******** adding %s to product list\n", pids[i].utf8().get_data());
		NSString *pid = [[NSString alloc] initWithUTF8String:pids[i].utf8().get_data()];
		[array addObject:pid];
	}

	NSSet *events = [[NSSet alloc] initWithArray:array];

	[gamebridge_request_delegate performRequestWithEventIDs:events];

	return OK;
}

Error GameBridge::gamebridge_refresh() {
	printf("refreshing!\n");
	return OK;
}

Error GameBridge::gamebridge_invoke(Dictionary p_params) {
/*
	ERR_FAIL_COND_V(![SKPaymentQueue canMakePayments], ERR_UNAVAILABLE);
	if (![SKPaymentQueue canMakePayments]) {
		return ERR_UNAVAILABLE;
	}
*/

	printf("invoking!\n");
	ERR_FAIL_COND_V(!p_params.has("event_id"), ERR_INVALID_PARAMETER);

NSMutableDictionary *paramsDict = [[NSMutableDictionary alloc] init];
    
    // Loop through all keys in the p_params dictionary
    for (int i = 0; i < p_params.keys().size(); ++i) {
        Variant key = p_params.keys()[i]; // Get the key as a Variant
        Variant value = p_params[key]; // Get the corresponding value for this key from p_params
        
        // Convert the key and value to NSString and add to paramsDict
        NSString *keyString = [[NSString alloc] initWithUTF8String:String(key).utf8().get_data()];
        NSString *valueString;
        
        if (value.get_type() == Variant::STRING) {
            // If the value is already a string, convert directly
            valueString = [[NSString alloc] initWithUTF8String:value.operator String().utf8().get_data()];
        } else {
            // For non-string values, you might want to convert them to a string or handle differently
            // This example shows converting to a string for simplicity
            valueString = [[NSString alloc] initWithUTF8String:String(value).utf8().get_data()];
        }
        
        [paramsDict setObject:valueString forKey:keyString];
    }

// TODO - loop through all keys
	NSString *pid = [[NSString alloc] initWithUTF8String:String(p_params["event_id"]).utf8().get_data()];
    //[gamebridge_observer postNewNotificationWithDictionary: @{@"event_id": pid}];
    [gamebridge_observer postNewNotificationWithDictionary: paramsDict];

	return [gamebridge_request_delegate performRequestWithEventID:pid];
}

int GameBridge::get_pending_event_count() {
	return pending_events.size();
}

Variant GameBridge::pop_pending_event() {
	Variant front = pending_events.front()->get();
	pending_events.pop_front();

	return front;
}

void GameBridge::_post_event(Variant p_event) {
	pending_events.push_back(p_event);
}

void GameBridge::_record_transaction(String event_key) {
	String skey = "event_transaction/" + event_key;
	NSString *key = [[NSString alloc] initWithUTF8String:skey.utf8().get_data()];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

GameBridge *GameBridge::get_singleton() {
	return instance;
}

GameBridge::GameBridge() {
	ERR_FAIL_COND(instance != NULL);
	instance = this;

	gamebridge_request_delegate = [[GodotGameBridgeDelegate alloc] init];
	gamebridge_observer = [[GodotGameBridgeObserver alloc] init];

	//[[SKPaymentQueue defaultQueue] addTransactionObserver:gamebridge_observer];
}

void GameBridge::gamebridge_transaction(String key) {
	NSString *event_id = [NSString stringWithCString:key.utf8().get_data() encoding:NSUTF8StringEncoding];

	[gamebridge_observer finishTransactionWithEventID:event_id];
}

void GameBridge::set_auto_finish_transaction(bool b) {
	gamebridge_observer.shouldAutoFinishTransactions = b;
}

GameBridge::~GameBridge() {
	[gamebridge_request_delegate reset];
	[gamebridge_observer reset];

	gamebridge_request_delegate = nil;
//	[[SKPaymentQueue defaultQueue] removeTransactionObserver:gamebridge_observer];
	gamebridge_observer = nil;
}
