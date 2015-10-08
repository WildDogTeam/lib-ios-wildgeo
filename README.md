# WilddogGeo for iOS — Realtime location queries with Wilddog

WilddogGeo is an open-source library for iOS that allows you to store and query a
set of keys based on their geographic location.

At its heart, WilddogGeo simply stores locations with string keys. Its main
benefit however, is the possibility of querying keys within a given geographic
area - all in realtime.

WilddogGeo uses the [Wilddog](https://www.wilddog.com/) database for
data storage, allowing query results to be updated in realtime as they change.
WilddogGeo *selectively loads only the data near certain locations, keeping your
applications light and responsive*, even with extremely large datasets.

A compatible WilddogGeo client is also available for [JavaScript](https://github.com/WildDogTeam/lib-js-wildgeo).

### Integrating WilddogGeo with your data

WilddogGeo is designed as a lightweight add-on to Wilddog. However, to keep things
simple, WilddogGeo stores data in its own format and its own location within
your Wilddog database. This allows your existing data format and security rules to
remain unchanged and for you to add WilddogGeo as an easy solution for geo queries
without modifying your existing data.

### Example Usage
Assume you are building an app to rate bars and you store all information for a
bar, e.g. name, business hours and price range, at `/bars/<bar-id>`. Later, you
want to add the possibility for users to search for bars in their vicinity. This
is where WilddogGeo comes in. You can store the location for each bar using
WilddogGeo, using the bar IDs as WilddogGeo keys. WilddogGeo then allows you to easily
query which bar IDs (the keys) are nearby. To display any additional information
about the bars, you can load the information for each bar returned by the query
at `/bars/<bar-id>`.




## Downloading WilddogGeo for iOS

In order to use WilddogGeo in your project, you need to download the framework and
add it to your project. You also need to [add the Wilddog
framework](https://z.wilddog.com/ios/quickstart)
and the CoreLocation framework to your project.

You can include the WilddogGeo
Xcode project from this repo in your project.



## Getting Started with Wilddog

WilddogGeo requires Wilddog in order to store location data. You can [sign up here for a free
account](https://www.wilddog.com/account/login).


### WilddogGeo

A `WilddogGeo` object is used to read and write geo location data to your Wilddog database
and to create queries. To create a new `WilddogGeo` instance you need to attach it to a Wilddog database reference:

##### Objective-C

	Wilddog *geoRef = [[Wilddog alloc] 	initWithUrl:@"https://<your-Wilddog>.wildddogio.com/"];
	WilddogGeo *geo = [[WilddogGeo alloc] initWithWilddogRef:geoRef];


##### Swift

	let geoRef = Wilddog(url: "https://<your-wilddog>.wilddogio.com/")
	let geo = WilddogGeo(geoRef: geoRef)


Note that you can point your reference to anywhere in your Wilddog database.

#### Setting location data

In WilddogGeo you can set and query locations by string keys. To set a location for a key
simply call the `setLocation:forKey` method:

##### Objective-C
```
[geo setLocation:[[CLLocation alloc] initWithLatitude:37.7853889 longitude:-122.4056973]
              forKey:@"wilddog-hq"];
```

##### Swift
````
geo.setLocation(CLLocation(latitude: 37.7853889, longitude: -122.4056973), forKey: "wilddog-hq")
````

Alternatively a callback can be passed which is called once the server
successfully saves the location:

##### Objective-C
```    
[geo setLocation:[[CLLocation alloc] initWithLatitude:37.7853889 longitude:-122.4056973]
              forKey:@"wilddog-hq"
 withCompletionBlock:^(NSError *error) {
     if (error != nil) {
         NSLog(@"An error occurred: %@", error);
     } else {
         NSLog(@"Saved location successfully!");
     }
 }];
```

##### Swift
````
geo.setLocation(CLLocation(latitude: 37.7853889, longitude: -122.4056973), forKey: "wilddog-hq") { (error) in
  if (error != nil) {
    println("An error occured: \(error)")
  } else {
    println("Saved location successfully!")
  }
}
````

To remove a location and delete the location from your database simply call:

##### Objective-C
```
[geo removeKey:@"wildddog-hq"];
```

##### Swift
````
geo.removeKey("wilddog-hq")
````

#### Retrieving a location

Retrieving locations happens with callbacks. If the key is not present in
WilddogGeo, the callback will be called with `nil`. If an error occurred, the
callback is passed the error and the location will be `nil`.

##### Objective-C
```
[geo getLocationForKey:@"wilddog-hq" withCallback:^(CLLocation *location, NSError *error) {
    if (error != nil) {
        NSLog(@"An error occurred getting the location for \"wilddog-hq\": %@", [error localizedDescription]);
    } else if (location != nil) {
        NSLog(@"Location for \"wilddog-hq\" is [%f, %f]",
              location.coordinate.latitude,
              location.coordinate.longitude);
    } else {
        NSLog(@"WilddogGeo does not contain a location for \"wilddog-hq\"");
    }
}];
```

##### Swift
````swift
geo.getLocationForKey("wilddog-hq", withCallback: { (location, error) in
  if (error != nil) {
    println("An error occurred getting the location for \"wilddog-hq\": \(error.localizedDescription)")
  } else if (location != nil) {
    println("Location for \"wilddog-hq\" is [\(location.coordinate.latitude), \(location.coordinate.longitude)]")
  } else {
    println("WilddogGeo does not contain a location for \"wilddog-hq\"")
  }
})
````

### Geo Queries

WilddogGeo allows you to query all keys within a geographic area using `GFQuery`
objects. As the locations for keys change, the query is updated in realtime and fires events
letting you know if any relevant keys have moved. `GFQuery` parameters can be updated
later to change the size and center of the queried area.

##### Objective-C
```
CLLocation *center = [[CLLocation alloc] initWithLatitude:37.7832889 longitude:-122.4056973];
// Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
GFCircleQuery *circleQuery = [geo queryAtLocation:center withRadius:0.6];

// Query location by region
MKCoordinateSpan span = MKCoordinateSpanMake(0.001, 0.001);
MKCoordinateRegion region = MKCoordinateRegionMake(center.coordinate, span);
GFRegionQuery *regionQuery = [geo queryWithRegion:region];
```

#### Swift
````
let center = CLLocation(latitude: 37.7832889, longitude: -122.4056973)
// Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
var circleQuery = geo.queryAtLocation(center, withRadius: 0.6)

// Query location by region
let span = MKCoordinateSpanMake(0.001, 0.001)
let region = MKCoordinateRegionMake(center.coordinate, span)
var regionQuery = geo.queryWithRegion(region)
````

#### Receiving events for geo queries

There are three kinds of events that can occur with a geo query:

1. **Key Entered**: The location of a key now matches the query criteria.
2. **Key Exited**: The location of a key no longer matches the query criteria.
3. **Key Moved**: The location of a key changed but the location still matches the query criteria.

Key entered events will be fired for all keys initially matching the query as well as any time
afterwards that a key enters the query. Key moved and key exited events are guaranteed to be
preceded by a key entered event.

To observe events for a geo query you can register a callback with `observeEventType:withBlock:`:

##### Objective-C
```
WilddogHandle queryHandle = [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
    NSLog(@"Key '%@' entered the search area and is at location '%@'", key, location);
}];
```

##### Swift
````
var queryHandle = query.observeEventType(GFEventTypeKeyEntered, withBlock: { (key: String!, location: CLLocation!) in
  println("Key '\(key)' entered the search area and is at location '\(location)'")
})
````

To cancel one or all callbacks for a geo query, call
`removeObserverWithWilddogHandle:` or `removeAllObservers:`, respectively.

#### Waiting for queries to be "ready"

Sometimes you want to know when the data for all the initial keys has been
loaded from the server and the corresponding events for those keys have been
fired. For example, you may want to hide a loading animation after your data has
fully loaded. `GFQuery` offers a method to listen for these ready events:

##### Objective-C
```
[query observeReadyWithBlock:^{
    NSLog(@"All initial data has been loaded and events have been fired!");
}];
```

##### Swift
````
query.observeReadyWithBlock({
  println("All initial data has been loaded and events have been fired!")
})
````

Note that locations might change while initially loading the data and key moved and key
exited events might therefore still occur before the ready event was fired.

When the query criteria is updated, the existing locations are re-queried and the
ready event is fired again once all events for the updated query have been
fired. This includes key exited events for keys that no longer match the query.

#### Updating the query criteria

To update the query criteria you can use the `center` and `radius` properties on
the `GFQuery` object. Key exited and key entered events will be fired for
keys moving in and out of the old and new search area, respectively. No key moved
events will be fired as a result of the query criteria changing; however, key moved
events might occur independently.


## 注册 Wilddog

WilddogGeo 需要 Wilddog 来同步和存储数据。您可以在这里[注册](https://www.wilddog.com/my-account/signup)一个免费帐户。


## 支持
如果在使用过程中有任何问题，请提 [issue](https://github.com/WildDogTeam/demo-ios-wilddoggeo/issues) ，我会在 Github 上给予帮助。

## 相关文档

* [Wilddog 概览](https://z.wilddog.com/overview/guide)
* [iOS SDK快速入门](https://z.wilddog.com/ios/quickstart)
* [iOS SDK 开发向导](https://z.wilddog.com/ios/guide/1)
* [iOS SDK API](https://z.wilddog.com/ios/api)
* [下载页面](https://www.wilddog.com/download/)
* [Wilddog FAQ](https://z.wilddog.com/faq/qa)


## License
[MIT](http://wilddog.mit-license.org/)

## 感谢 Thanks

demo-ios-wilddoggeo is built on and with the aid of several  projects. We would like to thank the following projects for helping us achieve our goals:

Open Source:

* [Geofire](https://github.com/firebase/geofire-objc) GeoFire for Objective-C - Realtime location queries with Firebase