###
支持的脚本为：
    当前时间：now
    申请人：applicant.name, applicant.organization, applicant.organizations, applicant.hr
    处理人：approver.name, approver.organization, approver.organizations, applicant.hr
###

InstanceMacro.check = (macro) ->
	if _.isString(macro) && macro.indexOf("{") > -1 && macro.indexOf("}") > -1 && macro.indexOf("auto_number(") < 0
		return true;
	return false



InstanceMacro.run = (macro) ->

	form_version = WorkflowManager.getInstanceFormVersion();

	_context = Form_formula.init_formula_values(form_version.fields, {});

	_context.now = new Date()

	if InstanceMacro.check(macro)

		macro = Form_formula.prependPrefixForFormula("_context", macro)

		return eval(macro)