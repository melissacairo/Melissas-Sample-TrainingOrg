/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class lp_InvocableAssignPlan {
    global lp_InvocableAssignPlan() {

    }
    @InvocableMethod(label='Assign Plan (Deprecated)' description='Deprecated')
    global static void assignPlan(List<litify.lp_InvocableAssignPlan.PlanAssignmentRequest> requests) {

    }
global class PlanAssignmentRequest {
    @InvocableVariable(label='Activity Owner Id Override' description='Optional param to override owner of activities' required=false)
    global Id activityOwnerIdOverride;
    @InvocableVariable(label='Due Date Override' description='Optional parameter to override task due dates' required=false)
    global Date dueDateOverride;
    @InvocableVariable(label='Plan Name Override' description='Optional parameter to override the plan name' required=false)
    global String nameOverride;
    @InvocableVariable(label='Parent Record Id' description='Id of the record to which the plan needs to be assigned' required=true)
    global Id parentRecordId;
    @InvocableVariable(label='Plan Template Id' description='Plan Template Id' required=true)
    global Id planTemplateId;
    @InvocableVariable(label='Source Record Id' description='Record id from which we start automation' required=true)
    global Id sourceRecordId;
    global PlanAssignmentRequest() {

    }
}
}
