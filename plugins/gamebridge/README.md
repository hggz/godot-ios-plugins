# Godot iOS GameBridge plugin

To use this plugin you will have to interface with your godot game from another ios app.

## Example

```
var _gb = null

func check_events():
    while _gb.get_pending_event_count() > 0:
        var event = gamebridge.pop_pending_event()
	if event.result=="ok": # other possible values are "progress", "error", "unhandled", "completed"
	
	    # print(event.event_id)
            match event.type:
                'product_info':
		    # fields: titles, descriptions, prices, ids, localized_prices, currency_codes, invalid_ids
		    ...
                'purchase':
		    # fields: product_id, transaction_id, receipt		
                    ...
                'restore':
                    # fields: product_id, transaction_id, receipt
                    ...
                'completed':
                    # Now the last in-app purchase restore has been sent,
                    # so if you didn't get any, the user doesn't have
                    # any purchases to restore.
                    ...
	
func _on_Purchase_button_down():
    var result = _gb.restore_purchases()
    ...

    var result = _gb.purchase({'event_id': "product_1"})
    ...

func _on_Restore_button_down(): # such button is required by Apple for non-consumable products
    var result = _gb.gamebridge_refresh()
    ...
    
func _ready():
    if Engine.has_singleton("GameBridge"):
        _gb = Engine.get_singleton('GameBridge')
	var result = _gb.request_product_info( { "event_ids": ["product_1", "product_2"] } )
        if result == OK:
            print("Successfully started product info request")
            _gb.set_auto_finish_transaction(true)

            var timer = Timer.new()
            timer.wait_time = 1
            timer.connect("timeout", self, 'check_events')
            add_child(timer)
            timer.start()
        else:
            print("failed requesting product info")
    else:
        print("no app store plugin")
```

## Methods

`request_product_info(Dictionary products_dictionary)` - Loads the unique identifiers for your in-app products in order to retrieve products information. Generates new event with `product_info` type. Identifiers should be the same as the ones used to setup your App Store purchases.  
`restore_purchases()` - Asks App Store payment queue to restore previously completed purchases. Generates new event with `restore` type.  
`purchase(Dictionary product_dictionary)` - Adds a product payment request to the App Store payment queue. Generates new event with `purchase` type.  
`set_auto_finish_transaction(bool flag)` - Sets a value responsible for enabling automatic transaction finishing.  
`finish_transaction(String product_id)` - Notifies the App Store that the app finished processing the transaction.

## Properties

## Events reporting

`get_pending_event_count()` - Returns number of events pending from plugin to be processed.  
`pop_pending_event()` - Returns first unprocessed plugin event.
