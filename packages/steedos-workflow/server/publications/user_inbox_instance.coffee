Meteor.publishComposite "user_inbox_instance", ()->
	unless this.userId
		return this.ready()

	userSpaceIds = db.space_users.find({
		user: this.userId,
		user_accepted: true
	}, {fields: {space: 1}}).fetch().getEach("space");
	query = {space: {$in: userSpaceIds}}

	query.$or = [{inbox_users: this.userId}, {cc_users: this.userId}]

	find: ->
		db.instances.find(query, {
			fields: {
				space: 1,
				applicant_name: 1,
				flow: 1,
				inbox_users: 1,
				cc_users: 1,
				state: 1,
				name: 1,
				modified: 1,
				form: 1
			}, sort: {modified: -1}, skip: 0, limit: 200
		});
	children: [
		{
			find: (instance, post)->
				db.flows.find({_id: instance.flow}, {fields: {name: 1, space: 1}});
		}
	]

Meteor.publish 'my_inbox_instances', (spaceId)->
	unless this.userId
		return this.ready()

	self = this;

	#	userSpaceIds = db.space_users.find({
	#		user: this.userId,
	#		user_accepted: true
	#	}, {fields: {space: 1}}).fetch().getEach("space");

	query = {space: spaceId}

	query.$or = [{inbox_users: this.userId}, {cc_users: this.userId}]

	fields = {
		space: 1,
#		applicant_name: 1,
		flow: 1,
		inbox_users: 1,
		cc_users: 1,
		state: 1,
#		name: 1,
#		modified: 1,
		form: 1
	}

	handle = db.instances.find(query, {sort: {modified: -1}, skip: 0, limit: 500}).observeChanges {
		added: (id)->
			instance = db.instances.findOne({_id: id}, {fields: fields})
			return if not instance
			instance.is_cc = instance.cc_users?.includes(self.userId) || false
			delete instance.cc_users
			self.added("instances", id, instance)
		changed: (id)->
			instance = db.instances.findOne({_id: id}, {fields: fields})
			return if not instance
			instance.is_cc = instance.cc_users?.includes(self.userId) || false
			delete instance.cc_users
			self.changed("instances", id, instance);
		removed: (id)->
			self.removed("instances", id);
	}

	self.ready();
	self.onStop ()->
		handle.stop()


_get_flow_instances_aggregate = (spaceId, userId, _items, callback)->
	db.instances.rawCollection().aggregate [
		{
			$match: {
				space: spaceId,
				$or: [{inbox_users: userId}, {cc_users: userId}]
			}
		},
		{
			$group: {
				_id: "$flow", count: {$sum: 1}
			}
		}
	], (err, data)->
		if err
			throw new Error(err)

		data.forEach (doc) ->
			_items.push doc

		if callback && _.isFunction(callback)
			callback()
		return

_async_get_flow_instances_aggregate = Meteor.wrapAsync(_get_flow_instances_aggregate)

Meteor.publish 'my_inbox_flow_instances_count', (spaceId)->

	unless this.userId
		return this.ready()

	self = this;

	query = {space: spaceId}

	query.$or = [{inbox_users: this.userId}, {cc_users: this.userId}]

	fields = {
		space: 1,
		applicant_name: 1,
		flow: 1,
		inbox_users: 1,
		cc_users: 1,
		state: 1,
		name: 1,
		modified: 1,
		form: 1
	}

	data = []

	_async_get_flow_instances_aggregate(spaceId, self.userId, data)

	self.added("flow_instances", spaceId, {flows: data});


	handle = db.instances.find(query).observeChanges {
		added: (id)->
			data = []
			_async_get_flow_instances_aggregate(spaceId, self.userId, data)
			self.changed("flow_instances", spaceId, {flows: data});
#		changed: (id)->
#			data = []
#			_async_get_flow_instances_aggregate(spaceId, self.userId, data)
#			self.changed("flow_instances", spaceId, {flows: data});
		removed: (id)->
			data = []
			_async_get_flow_instances_aggregate(spaceId, self.userId, data)
			self.changed("flow_instances", spaceId, {flows: data});
	}

	self.ready();
	self.onStop ()->
		handle.stop()