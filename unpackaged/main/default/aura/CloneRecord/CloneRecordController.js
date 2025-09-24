({
    init: function (component, event, helper) {
       helper.getOptions(component);
       helper.getName(component);
    },
    handleChange: function (component, event) {
        component.set("v.value",event.getParam('value'));
    },
    cloneRecords : function(component, event, helper) {
        helper.cloneRecordsFromObject(component,event);
    }
})