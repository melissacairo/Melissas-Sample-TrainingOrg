/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class lp_InvocableUpdatePlansTriggers {
    global lp_InvocableUpdatePlansTriggers() {

    }
    @InvocableMethod(label='Update Plans Triggers are Enabled' description='Update the plans triggers to either be enabled or disabled')
    global static void updatePlansTriggers(List<litify.lp_InvocableUpdatePlansTriggers.UpdatePlansTriggersRequest> requests) {

    }
global class UpdatePlansTriggersRequest {
    @InvocableVariable(label='Are Triggers Enabled' description='Boolean value to indicated if the plans triggers should be enabled or disabled' required=true)
    global Boolean areTriggersEnabled;
    global UpdatePlansTriggersRequest() {

    }
}
}
