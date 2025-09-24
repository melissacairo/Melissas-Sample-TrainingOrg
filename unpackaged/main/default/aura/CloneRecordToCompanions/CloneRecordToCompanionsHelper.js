({
    getOptions : function(component,event,getInputkeyWord) {
        // call the apex class method 
        var action = component.get("c.getAvailableObjects");
        // set param to method  
        action.setParams({
            recId : component.get("v.recordId")
        });
        // set a callBack    
        var values = [];
        var selectedValues = [];
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var allValues = response.getReturnValue();
                // set searchResult list with return value from server.
                for (var i = 0; i < allValues.length; i++) {
                    values.push({
                        label: allValues[i].label,
                        value: allValues[i].value
                    });
                    selectedValues.push(allValues[i].value)
                }
                component.set("v.options", values);
                component.set("v.value", selectedValues);
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    },
    getMatters : function(component,event,getInputkeyWord) {
        // call the apex class method 
        var action = component.get("c.getCompanionMatters");
        // set param to method  
        action.setParams({ 
            recId : component.get("v.recordId")
        });
        // set a callBack    
        var values = [];
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var allValues = response.getReturnValue();
                var selectedRecords = [];
                // set searchResult list with return value from server.
                for (var i = 0; i < allValues.length; i++) {
                    console.log(allValues[i]);
                    values.push({
                        label: allValues[i].litify_pm__Display_Name__c,
                        value: allValues[i].Id
                    });
                    selectedRecords.push(allValues[i].Id);
                }
                console.log("v.l_matters"+values);
                component.set("v.l_matters", values);
                component.set("v.l_selectedMatters", selectedRecords);
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    },
    cloneChildRecords : function(component,event) {
        component.set("v.Spinner", true);
        // call the apex class method 
        var selectedOptions = component.get("v.value");
        var selectedMatters = component.get("v.l_selectedMatters");
        var action = component.get("c.cloneChildRecordsToCompanions");
        // set param to method  
        action.setParams({
            'matterId': component.get("v.recordId"),
            'l_objects': selectedOptions, 
            'l_matterIds': selectedMatters
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            component.set("v.Spinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var records = response.getReturnValue();
                var message = "The record has been cloned successfully to related matter records:"
                var templateArray = [];
                var linkArray = [];
                var variant = 'success';
                for (var i = 0; i < records.length; i++) {
                    templateArray.push('{'+i+'}');
                    linkArray.push({
                        url: records[i].value,
                        label: records[i].label,
                    });
                }
				message = message + ' '+templateArray.join(', ');   
                if (templateArray.length == 0 ) {
                    variant = 'warning';
                    message = "Record cannot be cloned because it already exist on related companions."
                }
                component.find('notifLib').showToast({
                    "variant": variant,
                    "title": "Record clone.",
                    "mode":"sticky",
                    "message": message,
                    "messageData": linkArray 
                });
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            title : "Record clone.",
                            type:"error",
                            message :" Error message: " + errors[0].message
                        });
                        resultsToast.fire();
                    }
                    else {
                        console.log("Unknown error");
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Unknown problem, response state: " + state);
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
        
    },
})