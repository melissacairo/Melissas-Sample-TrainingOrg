/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class lp_InvocableAssignList {
    global lp_InvocableAssignList() {

    }
    @InvocableMethod(label='Assign List (Deprecated)' description='Deprecated')
    global static void assignList(List<litify.lp_InvocableAssignList.ListAssignmentRequest> requests) {

    }
global class ListAssignmentRequest {
    @InvocableVariable(label='Activity Owner Id Override' description='Optional param to override owner of activities' required=false)
    global Id activityOwnerIdOverride;
    @InvocableVariable(label='Due Date Override' description='Optional parameter to override task due dates' required=false)
    global Date dueDateOverride;
    @InvocableVariable(label='List Template Id' description='List Template Id' required=true)
    global Id listTemplateId;
    @InvocableVariable(label='List Name Override' description='Optional parameter to override the list name' required=false)
    global String nameOverride;
    @InvocableVariable(label='Parent Record Id' description='Id of the record to which list needs to be assigned' required=true)
    global Id parentRecordId;
    @InvocableVariable(label='Source Record Id' description='Record id from which we start automation' required=true)
    global Id sourceRecordId;
    global ListAssignmentRequest() {

    }
}
}
