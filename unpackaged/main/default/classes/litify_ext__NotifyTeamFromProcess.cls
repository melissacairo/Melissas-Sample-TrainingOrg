/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class NotifyTeamFromProcess {
    global NotifyTeamFromProcess() {

    }
    @InvocableMethod(label='Notify Matter team members')
    global static void notifyTeam(List<litify_ext.NotifyTeamFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='Related Matter Id to find team members.' required=true)
    global Id matterId;
    @InvocableVariable(label='Matter Roles name, separated by ";". If this param filled emails will be send only to member with specified roles.' required=false)
    global String matterRolesStr;
    @InvocableVariable(label='Salesforce Classic Email Template id.' required=true)
    global Id templateId;
    @InvocableVariable(label='Record id which used in email template.' required=true)
    global Id whatId;
    global InputParam() {

    }
}
}
