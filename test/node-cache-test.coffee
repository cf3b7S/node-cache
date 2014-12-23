assert = require('assert')
_ = require('lodash')
NodeCache = require('../lib/node-cache')
myCache = new NodeCache()

randomString = (length) ->
	chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

	length ?= 10
	randomstring = ''
	for i in [1..length]
		rnum = Math.floor(Math.random() * chars.length)
		randomstring += chars.substring(rnum, rnum + 1)
	randomstring

describe 'node-cache', ->
	key = randomString()
	value = randomString(100)
	value2 = randomString(100)

	keyTTL = randomString()
	valueTTL = randomString(100)

	mdata = [{
		key: randomString()
		value: randomString(100)
	}, {
		key: randomString()
		value: randomString(100)
	}]
	mkey = _.pluck(mdata, 'key')
	mvalue = _.pluck(mdata, 'value')

	describe '#set', ->
		it 'should return true', ->
			assert.equal(true, myCache.set(key, value))
		it 'keys should equal 1', ->
			assert.equal(1, myCache.stats.keys)
		it 'ksize should equal 10', ->
			assert.equal(10, myCache.stats.ksize)
		it 'vsize should equal 100', ->
			assert.equal(100, myCache.stats.vsize)

	describe '#get', ->
		it 'should equal value', ->
			assert.equal(value, myCache.get(key))
		it 'hits should equal 1', ->
			assert.equal(1, myCache.stats.hits)

	describe '#get undefined key', ->
		it 'should return null', ->
			assert.equal(null, myCache.get('xxx'))
		it 'misses return 1', ->
			assert.equal(1, myCache.stats.misses)

	describe '#update', ->
		it 'should equal value2', ->
			myCache.set(key, value2)
			assert.equal(value2, myCache.get(key))
		it 'hits should equal 2', ->
			assert.equal(2, myCache.stats.hits)


	describe '#del', ->
		it 'should return 1', ->
			assert.equal(1, myCache.del(key))
		it 'keys should equal 0', ->
			assert.equal(0, myCache.stats.keys)
		it 'undefined key should return 0', ->
			assert.equal(0, myCache.del('xxx'))


	describe '#ttl', ->
		it 'unexist key should return false', ->
			assert.equal(false, myCache.ttl(keyTTL, 1))
		it 'exist key should return true', ->
			myCache.set(keyTTL, valueTTL)
			assert.equal(true, myCache.ttl(keyTTL, 1))

	describe '#set with ttl', ->
		it 'should equal value', (done)->
			this.timeout(2000);
			setTimeout ()->
				assert.equal(valueTTL, myCache.get(keyTTL))
				done()
			, 500
		it 'should equal null', (done)->
			this.timeout(2000);
			setTimeout ()->
				assert.equal(null, myCache.get(keyTTL))
				done()
			, 1500


	describe '#flushAll', ->
		it 'should return true', ->
			assert.equal(true, myCache.flushAll(key))
		it 'stats should clear', ->
			assert.equal(0, myCache.stats.hits)
			assert.equal(0, myCache.stats.misses)
			assert.equal(0, myCache.stats.keys)
			assert.equal(0, myCache.stats.ksize)
			assert.equal(0, myCache.stats.vsize)

	describe  '#mset', ->
		it 'should return true', ->
			assert.equal(true, myCache.mset(mdata))
		it 'keys should equal 2', ->
			assert.equal(2, myCache.stats.keys)
		it 'ksize should equal 20', ->
			assert.equal(20, myCache.stats.ksize)
		it 'vsize should equal 200', ->
			assert.equal(200, myCache.stats.vsize)

	describe '#mget', ->
		it 'should equal value', ->
			keyTmp = myCache.mget(mkey)
			assert.equal(mvalue[0], keyTmp[0])
			assert.equal(mvalue[1], keyTmp[1])
		it 'hits should equal 2', ->
			assert.equal(2, myCache.stats.hits)

	describe '#mdel', ->
		it 'should return 2', ->
			assert.equal(2, myCache.mdel(mkey))
		it 'keys should equal 0', ->
			assert.equal(0, myCache.stats.keys)

	myCache.on 'set', (key, value)->
		console.log 'set', key
	myCache.on 'get', (key, value)->
		console.log 'get', key
	myCache.on 'del', (key, value)->
		console.log 'del', key
	myCache.on 'expired', (key, value)->
		console.log 'expired', key
	myCache.on 'flush', ()->
		console.log 'flush'