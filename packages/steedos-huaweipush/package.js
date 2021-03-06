Package.describe({
  name: 'steedos:huaweipush',
  version: '0.0.1',
  summary: 'Isomorphic Push notifications for APN and GCM',
  git: 'https://github.com/raix/push.git'
});

// Server-side push deps
Npm.depends({
  'requestretry': '1.12.2'
});


Package.onUse(function(api) {
  api.versionsFrom("1.2.1");
  api.use(['ecmascript']);

  api.use([
    'check',
    'underscore',
    'momentjs:moment',
    'mrt:moment-timezone'
  ], ['client', 'server']);

  api.addFiles('server/huaweiProvider.js', 'server');

  api.export('HuaweiPush');

});