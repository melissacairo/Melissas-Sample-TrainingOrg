/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class NotifyUsersFromProcess {
    global NotifyUsersFromProcess() {

    }
    @InvocableMethod(label='Notify Users')
    global static void notifyTeam(List<litify_ext.NotifyUsersFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='Related record id for User Fields' required=false)
    global Id relatedRecordId;
    @InvocableVariable(label='User Fields separated by ";"' required=false)
    global String strUserFields;
    @InvocableVariable(label='User id separated by ";"' required=false)
    global String strUsers;
    @InvocableVariable(label='Salesforce Classic Email Template id.' required=true)
    global Id templateId;
    @InvocableVariable(label='Record id which used in email template.' required=true)
    global Id whatId;
    global InputParam() {

    }
}
}
