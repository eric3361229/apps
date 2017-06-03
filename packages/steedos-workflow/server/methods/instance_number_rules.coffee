_eval = Npm.require('eval')

Meteor.methods
	instanceNumberBuilder: (name)->

		numberRules = db.instance_number_rules.findOne({name: name})

		if !numberRules
			throw new  Meteor.Error('error!', "#{name}")

		date = new Date()

		context = {}

		context._ = _

		_YYYY = date.getFullYear()

		_NUMBER = (numberRules.number || 0) + 1

		context.YYYY = _.clone(_YYYY)

		context.MM = date.getMonth() + 1

		if context.YYYY != numberRules.year
			_NUMBER = numberRules.first_number || 1

		context.NUMBER = _.clone(_NUMBER)

		rules = numberRules.rules.replace("{YYYY}", "' + YYYY + '").replace("{MM}", "' + MM + '").replace("{NUMBER}", "' + NUMBER + '")

		script = "var newNo = '#{rules}'; exports.newNo = newNo";

		try
			res = _eval(script, "newNo", context, false).newNo

			db.instance_number_rules.update({_id: numberRules._id}, {$set: {year: _YYYY, number: _NUMBER}})

		catch e
			res = {_error: e}

		return res;
