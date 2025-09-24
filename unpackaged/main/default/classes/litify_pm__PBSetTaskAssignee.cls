/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBSetTaskAssignee {
    global PBSetTaskAssignee() {

    }
    @InvocableMethod(label='Set Task Assignee' description='Manually sets the tasks' owner to the given user')
    global static void setTaskAssignee(List<litify_pm.PBSetTaskAssignee.PBSetTaskAssigneeWrapper> input) {

    }
global class PBSetTaskAssigneeWrapper {
    @InvocableVariable( required=false)
    global Task inputTask;
    @InvocableVariable( required=false)
    global Id newOwnerId;
    global PBSetTaskAssigneeWrapper() {

    }
}
}
