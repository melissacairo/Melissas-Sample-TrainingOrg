/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class lp_InvocableUpdateDueDatesForPlan {
    global lp_InvocableUpdateDueDatesForPlan() {

    }
    @InvocableMethod(label='Update Due Dates for Plan' description='Update the due dates for all tasks in the plan')
    global static void updateDueDatesForPlan(List<litify.lp_InvocableUpdateDueDatesForPlan.PlanDueDateUpdateRequest> requests) {

    }
global class PlanDueDateUpdateRequest {
    @InvocableVariable(label='Due Date Override' description='Optional parameter to override task due dates' required=false)
    global Date dueDateOverride;
    @InvocableVariable(label='Parent Record Id' description='Id of the record to which the plan needs to be assigned' required=true)
    global Id parentRecordId;
    @InvocableVariable(label='Plan  Id' description='Plan  Id' required=true)
    global Id planId;
    @InvocableVariable(label='Source Record Id' description='Record id from which we start automation' required=true)
    global Id sourceRecordId;
    global PlanDueDateUpdateRequest() {

    }
}
}
