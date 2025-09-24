({
	init: function (component, event, helper) {
       helper.getMatters(component);
       helper.getName(component);
    },
    cloneRecords : function(component, event, helper) {
        helper.cloneChildRecord(component,event);
    },
    handleChangeMatter: function (component, event) {
        component.set("v.l_selectedMatters",event.getParam('value'));
    },
})