/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class lp_InvocableUpdateDueDatesForList {
    global lp_InvocableUpdateDueDatesForList() {

    }
    @InvocableMethod(label='Update Due Dates for List' description='Update the due dates for all the activities in the List')
    global static void updateDueDatesForList(List<litify.lp_InvocableUpdateDueDatesForList.ListDueDateUpdateRequest> requests) {

    }
global class ListDueDateUpdateRequest {
    @InvocableVariable(label='Due Date Override' description='Override task due dates' required=false)
    global Date dueDate;
    @InvocableVariable(label='List Id' description='List Id' required=true)
    global Id listId;
    @InvocableVariable(label='Parent Record Id' description='Id of the record to which the list needs to be assigned' required=true)
    global Id parentRecordId;
    @InvocableVariable(label='Source Record Id' description='Record id from which we start automation' required=true)
    global Id sourceRecordId;
    global ListDueDateUpdateRequest() {

    }
}
}
