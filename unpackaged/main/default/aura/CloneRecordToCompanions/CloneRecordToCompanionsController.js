({
	init: function (component, event, helper) {
       helper.getOptions(component);
       helper.getMatters(component);
    },
    handleChange: function (component, event) {
        component.set("v.value",event.getParam('value'));
    },
    handleChangeMatter: function (component, event) {
        component.set("v.l_selectedMatters",event.getParam('value'));
    },
    cloneRecords : function(component, event, helper) {
        helper.cloneChildRecords(component,event);
    }
})