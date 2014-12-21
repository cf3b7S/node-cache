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
	mdata = [{
		key: randomString()
		value: randomString(100)
	}, {
		key: randomString()
		value: randomString(100)
	}]
	mkey = _.pluck(mdata, 'key')
	mvalue = _.pluck(mdata, 'value')

	describe '#set()', ->
		it 'should return true', ->
			assert.equal(true, myCache.set(key, value))
		it 'keys should equal 1', ->
			assert.equal(1, myCache.stats.keys)
		it 'ksize should equal 10', ->
			assert.equal(10, myCache.stats.ksize)
		it 'vsize should equal 100', ->
			assert.equal(100, myCache.stats.vsize)

	describe '#get()', ->
		it 'should equal value', ->
			assert.equal(value, myCache.get(key))
		it 'hits should equal 1', ->
			assert.equal(1, myCache.stats.hits)

	describe '#del()', ->
		it 'should return 1', ->
			assert.equal(1, myCache.del(key))
		it 'keys should equal 0', ->
			assert.equal(0, myCache.stats.keys)

	describe  '#mset()', ->
		it 'should return true', ->
			assert.equal(true, myCache.mset(mdata))
		it 'keys should equal 2', ->
			assert.equal(2, myCache.stats.keys)
		it 'ksize should equal 20', ->
			assert.equal(20, myCache.stats.ksize)
		it 'vsize should equal 200', ->
			assert.equal(200, myCache.stats.vsize)

	describe '#mget()', ->
		it 'should equal value', ->
			keyTmp = myCache.mget(mkey)
			assert.equal(mvalue[0], keyTmp[0])
			assert.equal(mvalue[1], keyTmp[1])
		it 'hits should equal 3', ->
			assert.equal(3, myCache.stats.hits)

	describe '#mdel()', ->
		it 'should return 2', ->
			assert.equal(2, myCache.mdel(mkey))
		it 'keys should equal 0', ->
			assert.equal(0, myCache.stats.keys)

