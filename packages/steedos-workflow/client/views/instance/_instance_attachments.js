InstanceAttachmentTemplate.helpers = {

	showMainTitle: function() {
		return Template.instance().workflowMainAttachTitle.get();
	},
	enabled_add_main_attachment: function() {
		var ins = WorkflowManager.getInstance();
		if (!ins)
			return false

		if (Session && Session.get("instancePrint"))
			return false

		var current_step = InstanceManager.getCurrentStep();
		// 分发的正文或者附件不显示转为pdf按钮
		// 如果有正文权限则为正文，否则分发为附件
		// 分发的附件不允许修改 删除 新增版本
		var main_attach_count = cfs.instances.find({
			'metadata.instance': ins._id,
			'metadata.current': true,
			'metadata.main': true
		}).count();

		var distribute_main_attach_count = 0;

		if (ins.distribute_from_instance) {
			var start_step = InstanceManager.getStartStep();
			if (start_step.can_edit_main_attach) {
				var distribute_main_attach_count = cfs.instances.find({
					'metadata.instance': ins.distribute_from_instance,
					'metadata.current': true,
					'metadata.main': true
				}).count();
			}
		}

		if (current_step.can_edit_main_attach == true && main_attach_count < 1 && distribute_main_attach_count < 1) {
			return true
		}

		// 正文最多只能有一个
		if (main_attach_count >= 1 || distribute_main_attach_count >= 1) {
			return false;
		}

		// 开始节点并且设置了可以上传正文才显示上传正文的按钮
		var current_step = InstanceManager.getCurrentStep();
		if (current_step && current_step.step_type == "start" && current_step.can_edit_main_attach == true)
			return true

		return false
	},

	enabled_edit_normal_attachment: function() {
		var ins = WorkflowManager.getInstance();
		if (!ins)
			return false

		if (Session && Session.get("instancePrint"))
			return false

		// 分发后的 附件，不可以编辑/删除，也不让上传新的附件
		if (ins.distribute_from_instance)
			return false

		if (Session.get("box") != "draft" && Session.get("box") != "inbox") {
			return false
		}

		var current_step = InstanceManager.getCurrentStep();
		if (current_step && (current_step.can_edit_normal_attach == true || current_step.can_edit_normal_attach == undefined))
			return true

		return false
	},

	main_attachment: function() {
		var ins = WorkflowManager.getInstance();
		if (!ins)
			return false

		var start_step = InstanceManager.getStartStep();

		// 如果是被分发的申请单并且有修改正文的权限，则显示原申请单文件
		var instanceId = (ins.distribute_from_instance && start_step.can_edit_main_attach == true) ? ins.distribute_from_instance : ins._id;

		return cfs.instances.findOne({
			'metadata.instance': instanceId,
			'metadata.current': true,
			'metadata.main': true
		});
	},

	normal_attachments: function() {
		var ins = WorkflowManager.getInstance();
		if (!ins)
			return false

		var selector = {
			'metadata.current': true,
			'metadata.main': {
				$ne: true
			},
		};

		var atts = new Array();

		if (ins.distribute_from_instance) {
			// 如果是被分发的申请单，则显示原申请单文件, 如果选择了将原表单存储为附件也要显示, 同时也要显示新上传的附件
			selector['metadata.instance'] = {
				$in: [ins.distribute_from_instance, ins._id]
			};
			// 如果原申请单有正文但是分发后没有正文权限，则原申请单正文显示在附件栏
			var start_step = InstanceManager.getStartStep();
			if (start_step && start_step.can_edit_main_attach != true) {
				var distribute_main = cfs.instances.findOne({
					'metadata.instance': ins.distribute_from_instance,
					'metadata.current': true,
					'metadata.main': true,
				});
				if (distribute_main) {
					atts.push(distribute_main);
				}
			}
		} else {
			selector['metadata.instance'] = ins._id;
		}

		atts = atts.concat(cfs.instances.find(selector, {
			sort: {
				'uploadedAt': 1
			}
		}).fetch())
		return atts;
	},

	showAttachments: function() {
		var ins = WorkflowManager.getInstance();
		if (!ins)
			return false;

		// 如果是被分发的申请单，则显示原申请单文件 和分发后申请单文件
		var instanceIds = _.compact([ins.distribute_from_instance, ins._id]);

		var attachments_count = cfs.instances.find({
			'metadata.instance': {
				$in: instanceIds
			},
			'metadata.current': true
		}).count();

		if (Session && Session.get("instancePrint") && attachments_count < 1)
			return false

		if (Session.get("box") == "draft" || Session.get("box") == "inbox" || attachments_count > 0)
			return true;
		else
			return false;
	},

	_t: function(key) {
		return TAPi18n.__(key)
	}

}

if (Meteor.isServer) {
	InstanceAttachmentTemplate.helpers._t = function(key) {
		locale = Template.instance().view.template.steedosData.locale
		return TAPi18n.__(key, {}, locale)
	}
	InstanceAttachmentTemplate.helpers.enabled_add_main_attachment = function() {
		return false
	};
	InstanceAttachmentTemplate.helpers.enabled_edit_normal_attachment = function() {
		return false
	};

	InstanceAttachmentTemplate.helpers.main_attachment = function() {
		var instance = Template.instance().view.template.steedosData.instance;
		var attachment = cfs.instances.findOne({
			'metadata.instance': instance._id,
			'metadata.current': true,
			'metadata.main': true
		});

		return attachment;
	};

	InstanceAttachmentTemplate.helpers.normal_attachments = function() {
		var steedosData = Template.instance().view.template.steedosData
		var instance = steedosData.instance;
		var attachments = cfs.instances.find({
			'metadata.instance': instance._id,
			'metadata.current': true,
			'metadata.main': {
				$ne: true
			},
			$or: [{
				'metadata.is_private': {
					$ne: true
				}
			}, {
				'metadata.is_private': true,
				"metadata.owner": steedosData.userId
			}]
		}).fetch();

		return attachments;
	};

	InstanceAttachmentTemplate.helpers.showAttachments = function() {
		var instance = Template.instance().view.template.steedosData.instance;
		var attachments = cfs.instances.find({
			'metadata.instance': instance._id,
			'metadata.current': true
		}).fetch();

		if (attachments && attachments.length > 0) {
			return true;
		}
		return false;
	}

	InstanceAttachmentTemplate.helpers.showMainTitle = function() {
		var instance = Template.instance().view.template.steedosData.instance;
		var main_attach_count = cfs.instances.find({
			'metadata.instance': instance._id,
			'metadata.current': true,
			'metadata.main': true
		}).count();

		return main_attach_count > 0
	}
}