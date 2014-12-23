_ = require('lodash')
EventEmitter = require('events').EventEmitter

module.exports = class NodeCache extends EventEmitter
	constructor: (@options = {})->

		# 数据容器，对于实体独立
		@data = {}

		# 配置项
		@options = _.assign({

			# 存活时间，0表示永远存活
			ttl: 0

			# 数组和对象的大小，用于计算容量
			objectValueSize: 80
			arrayValueSize: 40


			# 时间的倍乘，乘以1000表示单位为秒（s）
			timeMultiplier: 1000

			# 校验周期，默认每10分钟校验，0则不进行周期校验
			checkperiod: 600
		}, @options)

		# 统计数据容器
		@stats =
			hits: 0
			misses: 0
			keys: 0
			ksize: 0
			vsize: 0

		# 检查数据
		@checkAllData()

	# 设置单个键值对的值，及其过期时间
	# @param {String} key
	# @param {Type} value
	# @param {Number} ttl
	# @return {Boolean}
	# @api public
	set: (key, value, ttl = @options.ttl)=>
		if !_.isString(key) then return false
		keyExist = false

		# 数据已经存在，则恢复统计信息
		if @data[key]
			keyExist = true
			oldValue = @_unwrap(@data[key])
			@stats.vsize -= @_getValLength(oldValue)

		# 存储
		@data[key] = @_wrap(value, ttl)

		# 新数据更新统计信息
		if !keyExist
			@stats.ksize += @_getKeyLength(key)
			@stats.keys++
		@stats.vsize += @_getValLength(value)

		@emit('set', key, value)
		return true

	# 设置多个键值对的值，及其过期时间
	# @param {Array} datas
	# @return {Boolean}
	# @api public
	mset: (datas)=>
		for data in datas
			{key, value, ttl} = data
			@set(key, value, ttl)
		return true

	# 获取单个值
	# @param {String} keys
	# @return {Type}
	# @api public
	get: (key)=>
		if !_.isString(key) then return null
		if @data[key]? and @_checkData(key)
			@stats.hits++
			value = @_unwrap(@data[key])

			@emit('get', key, value)
			return value
		else
			@stats.misses++

			@emit('expired', key)
			return null

	# 获取多个值
	# @param {Array} keys
	# @return {Array}
	# @api public
	mget: (keys)=>
		if !_.isArray(keys) then return []
		return (@get key for key in keys)

	# 删除单个键，返回删除的键的个数
	# @param {String} key
	# @return {Number}
	# @api public
	del: (key)=>
		if !_.isString(key) then return 0
		if @data[key]?

			# 更新统计信息
			@stats.ksize -= @_getKeyLength(key)
			@stats.vsize -= @_getValLength(@_unwrap(@data[key]))
			@stats.keys--

			# 删除数据
			delete @data[key]

			# 发送消息
			@emit('del', key)
			return 1
		else
			@stats.misses++
			return 0

	# 删除多个键，返回删除的键的个数
	# @param {Array} keys
	# @return {Array}
	# @api public
	mdel: (keys)=>
		if !_.isArray(keys) then return 0
		delCount = 0
		for key in keys
			delCount += @del(key)
		return delCount

	# 更新单个键的存货时间，如果改键还未过期
	# @param {String} key
	# @param {Number} ttl
	# @return {Boolean}
	# @api public
	ttl: (key, ttl = @options.ttl)=>
		if @data[key]? and @_checkData(key)
			@data[key] = @_wrap(@_unwrap(@data[key]), ttl)
			return true
		else
			return false


	# 获取所有键
	# @return {Array}
	# @api public
	keys: =>
		_.keys(@data)

	# 清空所有数据
	# @api public
	flushAll: ()=>

		# 停止自动检查
		@_killCheckPeriod()

		# 存储数据清空
		@data = {}

		# 统计数据清空
		@stats =
			hits: 0
			misses: 0
			keys: 0
			ksize: 0
			vsize: 0


		# 检查所有数据，开启自动检查
		@checkAllData()

		# 触发清空事件
		@emit('flush')
		return true

	# 检查所有数据，删除所有不合法数据
	# 开启循环检查
	# @api private
	checkAllData: ()=>

		# 检查所有数据
		for key of @data
			@_checkData(key)

		# 开启周期检查
		if @options.checkperiod > 0
			checkperiod = @options.checkperiod * @options.timeMultiplier
			@checkTimeout = setTimeout(@checkAllData, checkperiod)
		return

	# 检查数据，如果不符合则删除
	# @param {String} key
	# @return {Boolean}
	# @api private
	_checkData: (key)=>
		wrapValue = @data[key]

		# 设定了过期时间，且已经过期
		if wrapValue.t isnt 0 and wrapValue.t < Date.now()
			@del(key)
			@emit('expired', key)
			return false
		else
			return true

	# 停止自动检查
	# @api private
	_killCheckPeriod: =>
		clearTimeout(@checkTimeout) if @checkTimeout?

	# 包装值
	# @param {Type} value
	# @param {Number} ttl
	# @return {Object}
	# @api private
	_wrap: (value, ttl = @options.ttl)=>
		now = Date.now()
		ttlMultiplicator = @options.timeMultiplier

		# 设置过期时间
		if ttl == 0
			livetime = 0
		else
			livetime = now + (ttl * ttlMultiplicator)

		wrapValue =
			t: livetime
			v: value

	# 获取值
	# @param {Object} value
	# @return {Object}
	# @api private
	_unwrap: (wrapValue)=>
		if wrapValue?.v?
			return wrapValue.v
		return null

	# 获取键的长度
	# @param {String} key
	# @return {Number}
	# @api private
	_getKeyLength: (key)=>
		key.length

	# 获取值的长度
	# @param {Type} value
	# @return {Number}
	# @api private
	_getValLength: (value)=>
		if _.isString(value)
			value.length
		else if @options.forceString
			JSON.stringify(value).length
		else if _.isArray(value)
			@options.arrayValueSize * value.length
		else if _.isNumber( value )
			8
		else if _.isObject( value )
			@options.objectValueSize * _.size(value)
		else
			0
