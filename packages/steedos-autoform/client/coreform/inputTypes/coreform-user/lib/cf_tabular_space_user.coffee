TabularTables.cf_tabular_space_user = new Tabular.Table({
	name: "cf_tabular_space_user",
	collection: db.space_users,
	columns: [
		{
			data: "_id",
			title: '<input type="checkbox" name="cf_reverse" id="cf_reverse">',
			orderable: false,
			width:'10px',
			render:  (val, type, doc) ->

				inputType = "checkbox";

				if !TabularTables.cf_tabular_space_user.customData?.multiple
					inputType = "radio"

				input = '<input type="' + inputType + '" class="list_checkbox" name="cf_contacts_ids" id="' + doc.user + '" value="' + doc.user + '" data-name="' + doc.name + '" data-email="' + doc.email + '"';

				if TabularTables.cf_tabular_space_user.customData?.defaultValues?.includes(doc.user)
					input += " checked "

				input += ">"
				return input
		},
		{
			data: "name",
			orderable: false,
			render:  (val, type, doc) ->
				return "<label data-user='" + doc.user + "' class='for-input'><div class='user-name'><img src='" + Steedos.absoluteUrl() + "avatar/"+doc.user+"?w=28&h=25&fs=14" +"' class='selectTag-profile img-circle'><font>" + doc.name + "</font></div></label>"
		},
		{
			data: "sort_no",
			title: "",
			orderable: true,
			visible: false
		},
		{
			data: "name",
			title: "",
			orderable: true,
			visible: false
		},{
			data: "email",
			title: "",
			orderable: false,
			visible: false
		}
	],
	onUnload:() ->
		return console.log("onUnload ok....");
	#select:
	#  style: 'single'
	dom: "tp",
	order:[[2,"desc"],[3,"asc"]],
	extraFields: ["_id", "name", "user", "sort_no", "email"],
	lengthChange: false,
	pageLength: 100,
	info: false,
	searching: true,
	responsive:
		details: false
	autoWidth: false,
	changeSelector: (selector, userId) ->
		unless userId
			return {make_a_bad_selector: 1}
		space = selector.space
		unless space
			if selector?.$and?.length > 0
				space = selector.$and.getProperty('space')[0]
		unless space
			return {make_a_bad_selector: 1}
		space_user = db.space_users.findOne({user: userId,space:space}, {fields: {_id: 1}})
		unless space_user
			return {make_a_bad_selector: 1}
		return selector

	#scrollY:        '400px',
	#scrollCollapse: true,
	pagingType: "numbers"

});