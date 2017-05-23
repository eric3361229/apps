Package.describe({
	name: 'steedos:accounts',
	version: '0.0.1',
	summary: 'Steedos Accounts',
	git: ''
});

Npm.depends({
	cookies: "0.6.1",
	phone: "1.0.3"
});

Package.onUse(function(api) {
	api.versionsFrom("1.2.1");

	api.use('coffeescript');
	api.use('check');
	api.use('tracker');
	api.use('session');
	api.use('useraccounts:bootstrap');
	api.use('underscore');
	api.use('blaze');
	api.use('templating');

	api.use('flemay:less-autoprefixer@1.2.0');
	api.use('simple:json-routes@2.1.0');
	api.use('kadira:blaze-layout@2.3.0');
	api.use('kadira:flow-router@2.10.1');

	api.use('tap:i18n@1.7.0');
	
	api.use('useraccounts:core');

	api.use('steedos:accounts-phone');
	api.use('steedos:base');



	//api.add_files("package-tap.i18n", ["client", "server"]);
	tapi18nFiles = ['i18n/en.i18n.json', 'i18n/zh-CN.i18n.json']
	api.addFiles(tapi18nFiles, ['client', 'server']);

	api.addFiles('lib/core.coffee');

	api.addFiles('server/methods/update_phone.coffee', 'server');
	api.addFiles('server/methods/disable_phone.coffee', 'server');

	api.addFiles('client/views/accounts_phone.html', 'client');
	api.addFiles('client/views/accounts_phone.coffee', 'client');
	
	api.addFiles('client/views/accounts_phone_verify.html', 'client');
	api.addFiles('client/views/accounts_phone_verify.coffee', 'client');
	
	api.addFiles('client/views/accounts_phone_password.html', 'client');
	api.addFiles('client/views/accounts_phone_password.coffee', 'client');
	
	api.addFiles('client/views/forgot_password_token.html', 'client');
	api.addFiles('client/views/forgot_password_token.coffee', 'client');

	api.addFiles('client/views/accounts.less', 'client');

	api.addFiles('client/router.coffee','client');
	
	api.addFiles('client/admin_menu.coffee','client');

	api.addFiles('client/subscribe.coffee', 'client');

	// EXPORT
	// api.export('FSSH');



});

Package.onTest(function(api) {

});
