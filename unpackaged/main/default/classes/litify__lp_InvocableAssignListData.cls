/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class lp_InvocableAssignListData {
    global lp_InvocableAssignListData() {

    }
    @InvocableMethod(label='Assign List' description='Assign a list to the provided record')
    global static List<litify.lp_InvocableAssignListData.ListAssignmentResult> assignList(List<litify.lp_InvocableAssignListData.ListAssignmentRequest> requests) {
        return null;
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
global class ListAssignmentResult {
    @InvocableVariable(label='Created List Id' description='The Id of the created list.' required=true)
    global Id createdListId;
    global ListAssignmentResult() {

    }
}
}
