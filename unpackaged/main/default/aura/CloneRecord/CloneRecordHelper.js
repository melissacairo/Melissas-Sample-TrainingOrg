({
    getName : function(component) {
        // call the apex class method 
        var action = component.get("c.getObjectName");
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
                component.set("v.ObjectName", response.getReturnValue());
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    },
    
    getOptions : function(component) {
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
    cloneRecordsFromObject : function(component,event) {
        component.set("v.Spinner", true);
        // call the apex class method 
        var selectedOptions = component.get("v.value");
        var action = component.get("c.clonesObjectRecord");
        // set param to method  
        action.setParams({
            'sObjectId': component.get("v.recordId"),
            'l_objects': selectedOptions,
            'numberOfRecords' : component.get("v.numberOfRecords"),
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            component.set("v.Spinner", false);
            if (state === "SUCCESS") {
                var records = response.getReturnValue();
                var message = "The record has been created successfully:"
                var templateArray = [];
                var linkArray = [];
                for (var i = 0; i < records.length; i++) {
                    templateArray.push('{'+i+'}');
                    linkArray.push({
                        url: records[i].value,
                        label: records[i].label,
                    });
                }
				message = message + ' '+templateArray.join(', ');   
                component.find('notifLib').showToast({
                    "variant":"success",
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
        
    }
})