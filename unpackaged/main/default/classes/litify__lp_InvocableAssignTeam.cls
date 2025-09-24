/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class lp_InvocableAssignTeam {
    global lp_InvocableAssignTeam() {

    }
    @InvocableMethod(label='Assign Team' description='Assign a team to the provided record')
    global static void assignTeam(List<litify.lp_InvocableAssignTeam.TeamAssignmentRequest> requests) {

    }
global class TeamAssignmentRequest {
    @InvocableVariable(label='Record Id' description='Id of the record to which the team needs to be assigned' required=true)
    global Id recordId;
    @InvocableVariable(label='Start Date' description='Team member start date' required=false)
    global Date startDate;
    @InvocableVariable(label='Team Id' description='Id of the team' required=true)
    global Id teamId;
    global TeamAssignmentRequest() {

    }
}
}
