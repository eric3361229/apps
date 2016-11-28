###
# Kick off the global namespace for Steedos.
# @namespace Steedos
###

db = {}
Steedos = 
	settings: {}
	db: db

@TabularTables = {};

if Meteor.isClient

	Steedos.isMobile = ()->
		return $(window).width() < 767

	Steedos.openWindow = (url, target)->
		target = "_blank"
		options = 'EnableViewPortScale=yes,toolbarposition=top,transitionstyle=fliphorizontal,closebuttoncaption=  x  '
		window.open(url, target, options);

	Steedos.getAccountBgBodyValue = ()->
		accountBgBody = db.steedos_keyvalues.findOne({user:Steedos.userId(),key:"bg_body"})
		if accountBgBody
			return accountBgBody.value
		else
			return {};

	Steedos.getAccountSkinValue = ()->
		accountSkin = db.steedos_keyvalues.findOne({user:Steedos.userId(),key:"skin"})
		if accountSkin
			return accountSkin.value
		else
			return {};

	Steedos.showHelp = ()->
		locale = Steedos.getLocale()
		country = locale.substring(3)
		window.open("http://www.steedos.com/" + country + "/help/", '_help', 'EnableViewPortScale=yes')

	# 左侧sidebar滚动条自适应
	Steedos.fixSideBarScroll = ()->
		if Steedos.isMobile()
			return
		if !$("#scrollspy").perfectScrollbar
			return
		if $("body").hasClass("sidebar-collapse")
			if $("#scrollspy").hasClass("ps-container")
				$("#scrollspy").perfectScrollbar("destroy")
		else if $("body").hasClass('sidebar-open')
			unless $("#scrollspy").hasClass("ps-container")
				$("#scrollspy").perfectScrollbar()
		else
			unless $("#scrollspy").hasClass("ps-container")
				$("#scrollspy").perfectScrollbar()

	#定义系统关闭函数，下次登录时自动跳转URL
	window.onunload = ()->
		# 判断用户是否登录
		if Meteor.userId()
			lastUrl = window.location.pathname
			localStorage.setItem('Steedos.lastURL:' + Meteor.userId(), lastUrl)


if Meteor.isServer
	Steedos.isSpaceAdmin = (spaceId, userId)->
		if !spaceId || !userId
			return false
		space = db.spaces.findOne(spaceId)
		if !space || !space.admins
			return false;
		return space.admins.indexOf(userId)>=0



# This will add underscore.string methods to Underscore.js
# except for include, contains, reverse and join that are 
# dropped because they collide with the functions already 
# defined by Underscore.js.

mixin = (obj) ->
	_.each _.functions(obj), (name) ->
		if not _[name] and not _.prototype[name]?
			func = _[name] = obj[name]
			_.prototype[name] = ->
				args = [this._wrapped]
				push.apply(args, arguments)
				return result.call(this, func.apply(_, args))

#mixin(_s.exports())