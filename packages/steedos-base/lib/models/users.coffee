db.users = Meteor.users;

db.users.allow
	# Allow user update own profile
	update: (userId, doc, fields, modifier) ->
		if userId == doc._id
			return true

db.users._simpleSchema = new SimpleSchema
	name: 
		type: String,
	username: 
		type: String,
		unique: true,
		optional: true
	steedos_id: 
		type: String,
		optional: true
		unique: true,
		autoform: 
			type: "text"
			readonly: true
	mobile: 
		type: String,
		optional: true,
		autoform:
			readonly: true
	locale: 
		type: String,
		optional: true,
		allowedValues: [
			"en-us",
			"zh-cn"
		],
		autoform: 
			type: "select",
			options: [{
				label: "简体中文",
				value: "zh-cn"
			},
			{
				label: "English",
				value: "en-us"
			}]
	
	email_notification:
		type: Boolean
		optional: true

	primary_email_verified:
		type: Boolean
		optional: true
		autoform: 
			omit: true
	last_logon:
		type: Date
		optional: true
		autoform: 
			omit: true
	is_cloudadmin:
		type: Boolean
		optional: true
		autoform: 
			omit: true
	is_deleted:
		type: Boolean
		optional: true,
		autoform:
			omit: true
	avatar: 
		type: String
		optional: true

if Meteor.isClient
	db.users._simpleSchema.i18n("users")

db.users.helpers
	spaces: ->
		spaces = []
		sus = db.space_users.find({user: this._id}, {fields: {space:1}})
		sus.forEach (su) ->
			spaces.push(su.space)
		return spaces;

	displayName: ->
		if this.name 
			return this.name
		else if this.username
			return this.username
		else if this.emails and this.emails[0]
			return this.emails[0].address


if Meteor.isServer
	db.users.create_secret = (userId, name)->

		secretToken =  Accounts._generateStampedLoginToken()

		secretToken.token = userId + "-" + secretToken.token

		hashedToken = Accounts._hashLoginToken(secretToken.token)

		secretToken.hashedToken = hashedToken

		secretToken.name = name

		u = db.users.findOne({_id: userId, "secrets.name": name})

		if !u
			db.users.update({_id: userId}, {$push: {secrets: secretToken}})
		
	db.users.checkEmailValid = (email) ->
		existed = db.users.find 
			"emails.address": email
		if existed.count()>0
			throw new Meteor.Error(400, "users_error_email_exists");

	db.users.checkUsernameValid = (username) ->
		existed = db.users.find 
			"username": username
		if existed.count()>0
			throw new Meteor.Error(400, "users_error_username_exists");

	db.users.validateUsername = (username, userId) ->
		user = db.users.findOne({username: { $regex : new RegExp("^" + s.trim(s.escapeRegExp(username)) + "$", "i") }, _id: { $ne: userId }})
		if user
			throw new Meteor.Error 'username-unavailable', 'username-unavailable'
		if !Meteor.settings.public?.accounts?.is_username_skip_minrequiredlength
			if username.length < 6
				throw new Meteor.Error 'username-minrequiredlength', "username-minrequiredlength"

		try
			if Meteor.settings.public?.accounts?.UTF8_Names_Validation
				nameValidation = new RegExp '^' + Meteor.settings.public.accounts.UTF8_Names_Validation + '$'
			else
				nameValidation = new RegExp '^[A-Za-z0-9-_.\u00C0-\u017F\u4e00-\u9fa5]+$'
		catch
			nameValidation = new RegExp '^[A-Za-z0-9-_.\u00C0-\u017F\u4e00-\u9fa5]+$'
		if not nameValidation.test username
			throw new Meteor.Error 'username-invalid', "username-invalid"

	db.users.validatePhone = (userId, doc, modifier) ->
		modifier.$set  = modifier.$set || {}
		if doc._id != userId and modifier.$set["phone.number"]
			if doc["phone.verified"] == true and doc["phone.number"] != modifier.$set["phone.number"]
				throw new Meteor.Error(400, "用户已验证手机，不能修改")

	db.users.before.insert (userId, doc) ->
		space_registered = doc.profile?.space_registered
		# # 从工作区特定的注册界面注册的用户，需要先判断下工作区是否存在
		if space_registered
			space = db.spaces.findOne(space_registered)
			if !space
				throw new Meteor.Error(400, "space_users_error_space_not_found")
		if doc.username
			db.users.validateUsername(doc.username, doc._id)
		doc.created = new Date();
		doc.is_deleted = false;
		if userId
			doc.created_by = userId;

		if doc.services?.google
			if doc.services.google.email && !doc.emails
				doc.emails = [{
					address: doc.services.google.email,
					verified: true
				}]
			if doc.services.google.picture
				doc.avatarUrl = doc.services.google.picture

		if doc.services?.facebook
			if doc.services.facebook.email && !doc.emails
				doc.emails = [{
					address: doc.services.facebook.email,
					verified: true
				}]

		if (doc.emails && !doc.steedos_id)
			if doc.emails.length>0
				doc.steedos_id = doc.emails[0].address

		if (doc.profile?.name && !doc.name)
			doc.name = doc.profile.name

		if (doc.profile?.locale && !doc.locale)
			doc.locale = doc.profile.locale

		if (doc.profile?.mobile && !doc.mobile)
			doc.mobile = doc.profile.mobile

		if !doc.steedos_id && doc.username
			doc.steedos_id = doc.username 

		if !doc.name
			doc.name = doc.steedos_id.split('@')[0]

		# if !doc.username
		# 	doc.username = doc.steedos_id.replace("@","_").replace(".","_")

		# for steedos chat
		if !doc.type
			doc.type = "user"
		if !doc.active
			doc.active = true
		if !doc.roles
			doc.roles = ["user"]

		if !doc.utcOffset
			doc.utcOffset = 8

		_.each doc.emails, (obj)->
			db.users.checkEmailValid(obj.address);


	db.users.after.insert (userId, doc) ->
		space_registered = doc.profile?.space_registered
		if space_registered
			# 从工作区特定的注册界面注册的用户，需要自动加入到工作区中
			user_email = doc.emails[0].address
			rootOrg = db.organizations.findOne({space:space_registered, is_company:true},{fields: {_id:1}})
			db.space_users.insert
				email: user_email
				user: doc._id
				name: doc.name
				organizations: [rootOrg._id]
				space: space_registered
				user_accepted: true
				is_registered_from_space: true

		if !space_registered and !(doc.spaces_invited?.length>0)
			# 不是从工作区特定的注册界面注册的用户，也不是邀请的用户
			# 即普通的注册用户，则为其新建一个自己的工作区
			space_name = doc.company || doc.profile?.company
			unless space_name
				space_name = doc.name + " " + trl("space")
			db.spaces.insert
				name: space_name
				owner: doc._id
				admins: [doc._id]

		try
			if !doc.services || !doc.services.password || !doc.services.password.bcrypt
				# 发送让用户设置密码的邮件
				# Accounts.sendEnrollmentEmail(doc._id, doc.emails[0].address)
				if doc.emails
					token = Random.secret();
					email = doc.emails[0].address
					now = new Date();
					tokenRecord = {
						token: token,
						email: email,
						when: now        
					};
					db.users.update(doc._id, {$set: {"services.password.reset":tokenRecord}});
					Meteor._ensure(doc, 'services', 'password').reset = tokenRecord;
					enrollAccountUrl = Accounts.urls.enrollAccount(token);
					url =  Accounts.urls.enrollAccount(token);
					locale = Steedos.locale(doc._id, true)
					subject = TAPi18n.__("users_email_create_account",{},locale)
					greeting = TAPi18n.__('users_email_hello', {}, locale) + "&nbsp;" + doc.name + ","
					content = greeting + "</br>" + TAPi18n.__('users_email_start_service', {} ,locale) + "</br>" + url + "</br>" + TAPi18n.__("users_email_thanks", {}, locale) + "</br>"
					MailQueue.send
						to: email
						from: Meteor.settings.email.from
						subject: subject
						html: content
		catch e
			console.log "after insert user: sendEnrollmentEmail, id: " + doc._id + ", " + e


	db.users.before.update  (userId, doc, fieldNames, modifier, options) ->
		db.users.validatePhone(userId, doc, modifier)
		if modifier.$unset && modifier.$unset.steedos_id == ""
			throw new Meteor.Error(400, "users_error_steedos_id_required");

		modifier.$set = modifier.$set || {};

		if modifier.$set.username
			db.users.validateUsername(modifier.$set.username, doc._id)

		# if doc.steedos_id && modifier.$set.steedos_id
		# 	if modifier.$set.steedos_id != doc.steedos_id
		# 		throw new Meteor.Error(400, "users_error_steedos_id_readonly");

		if userId
			modifier.$set.modified_by = userId;

		if modifier.$set['phone.verified'] is true
			newNumber = modifier.$set['phone.mobile']
			unless newNumber
				newNumber = doc.phone.mobile
			modifier.$set.mobile = newNumber
		modifier.$set.modified = new Date();

	db.users.after.update (userId, doc, fieldNames, modifier, options) ->
		modifier.$set = modifier.$set || {};
		modifier.$unset = modifier.$unset || {};

		if modifier.$set['phone.verified'] is true
			# db.users.before.update中对modifier.$set.mobile的修改这里识别不到，所以只能重新设置其值
			newNumber = modifier.$set['phone.mobile']
			unless newNumber
				newNumber = doc.phone.mobile
			modifier.$set.mobile = newNumber

		user_set = {}
		user_unset = {}
		if modifier.$set.name != undefined
			user_set.name = modifier.$set.name
		if modifier.$set.mobile != undefined
			user_set.mobile = modifier.$set.mobile

		if modifier.$unset.name != undefined
			user_unset.name = modifier.$unset.name
		if modifier.$unset.mobile != undefined
			user_unset.mobile = modifier.$unset.mobile

		# 更新users表中的相关字段，所有工作区信息同步
		if not _.isEmpty(user_set)
			db.space_users.direct.update({user: doc._id}, {$set: user_set}, {multi: true})
		if not _.isEmpty(user_unset)
			db.space_users.direct.update({user: doc._id}, {$unset: user_unset}, {multi: true})


	db.users.before.remove (userId, doc) ->
		throw new Meteor.Error(400, "users_error_cloud_admin_required");


			
	Meteor.publish 'userData', ->
		unless this.userId
			return this.ready()


		db.users.find this.userId,
			fields:
				steedos_id: 1
				name: 1
				mobile: 1
				locale: 1
				username: 1
				utcOffset: 1
				settings: 1
				is_cloudadmin: 1
				email_notification: 1,
				avatar: 1,
				"secrets.name": 1,
				"secrets.token": 1

if Meteor.isServer
	db.users._ensureIndex({
		"is_deleted": 1
	},{background: true})

	db.users._ensureIndex({
		"email": 1
	},{background: true})

	db.users._ensureIndex({
		"is_deleted": 1
		"email": 1
	},{background: true})

	db.users._ensureIndex({
		"_id": 1
		"created": 1
	},{background: true})

	db.users._ensureIndex({
		"_id": 1
		"created": 1,
		"modified": 1
	},{background: true})

	db.users._ensureIndex({
		"primary_email_verified": 1,
		"locale": 1,
		"name": 1,
		"_id": 1,
		"mobile": 1,
	},{background: true})

	db.users._ensureIndex({
		"primary_email_verified": 1,
		"locale": 1,
		"name": 1,
		"_id": 1,
		"mobile": 1,
		"created": 1
	},{background: true})

	db.users._ensureIndex({
		"primary_email_verified": 1,
		"locale": 1,
		"name": 1,
		"_id": 1,
		"mobile": 1,
		"created": 1,
		"last_logon": 1
	},{background: true})

	db.users._ensureIndex({
		"imo_uid": 1
	},{background: true})

	db.users._ensureIndex({
		"qq_open_id": 1
	},{background: true})

	db.users._ensureIndex({
		"created": 1
	},{background: true})

	db.users._ensureIndex({
		"last_logon": 1
	},{background: true})

	db.users._ensureIndex({
		"created": 1,
		"modified": 1
	},{background: true})

	db.users._ensureIndex({
		"name": 1
	},{background: true})

	db.users._ensureIndex({
		"lastLogin": 1
	},{background: true})

	db.users._ensureIndex({
		"status": 1
	},{background: true})

	db.users._ensureIndex({
		"active": 1
	},{background: true})

	db.users._ensureIndex({
		"type": 1
	},{background: true})

	db.users._ensureIndex({
		"steedos_id": 1
	},{background: true})
