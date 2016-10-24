Template.steedosAdminLayout.onCreated ->
	self = this;

	self.minHeight = new ReactiveVar(
		$(window).height());

	$(window).resize ->
		self.minHeight.set($(window).height());

Template.steedosAdminLayout.onRendered ->

	self = this;
	self.minHeight.set($(window).height());

	$('body').removeClass('fixed');
	$(window).resize();


Template.steedosAdminLayout.helpers 
	minHeight: ->
		return Template.instance().minHeight.get() + 'px'
	
	subsReady: ->
		return Steedos.subsBootstrap.ready()
		
	admin_collection_title: ->
		if Session.get('admin_collection_name')
				return t("" + Session.get('admin_collection_name'))

	enableAdd: ->
		c = Session.get('admin_collection_name')
		if c
			config = AdminConfig.collections[c]
			if config?.disableAdd    
				return false;
		return true

Template.steedosAdminLayout.events
	# "click #navigation-back": (e, t) ->
	# 	NavigationController.back(); 
	"click #admin-back": (e, t) ->
		c = Session.get('admin_collection_name')
		if c
			config = AdminConfig.collections[c]
			if config?.routerAdmin    
				FlowRouter.go(config.routerAdmin)
				return
		FlowRouter.go "/"  
