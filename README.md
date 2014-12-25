node-cache
==========

NodeJS internal in memory cache.

Written with coffee.

Inspired by [nodecache](https://github.com/tcs-de/nodecache).

#Install
---
```
sudo npm install n-cache
```

#Usage
---
```
var NodeCache = require('n-cache'),
	cache = new NodeCache();

// in usual
cache.set('foo', 'bar');
console.log(cache.get('foo'))

// in particular
cache.set('Alien', 'exist', 1); // Time in second

console.log(cache.get('Alien'));

setTimeout(function() {
    console.log(cache.get('Alien'));
}, 1500);
```


#API
---
### new NodeCache([options])
```
{
	ttl: 0 // Time of key expired, 0 stand for live for ever
	timeMultiplier: 1000 // Times on ttl, makes 1ttl for 1 second
	checkperiod: 600 // The period in seconds, check the expired data
}
```


### set(key, value, [ttl])

- Set a key value pair.
- It will be del after ttl seconds, unless ttl not passed in.
- Return true.

### get(key)
- Get a setted key.
- Return value.

### del(key)
- Del a setted key.
- Return 1, if key exist and not expired.

### flushall()
- Remove all data

### ttl(key, ttl)
- Reset the expire time for a exit key.

### keys()
- Return all the stored keys

### mset([{key: key1, value: value1, [ttl: ttl1]}...])

### mget([key1, key2...])

### mdel([key1, key2...])






