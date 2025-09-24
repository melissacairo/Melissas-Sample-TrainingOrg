/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class ShareRecordWithTeamFromProcess {
    global ShareRecordWithTeamFromProcess() {

    }
    @InvocableMethod(label='Extension - Share Record With Team Members')
    global static void shareRecord(List<litify_ext.ShareRecordWithTeamFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='AccessLevel ("Edit". "Read")' required=false)
    global String accessLevel;
    @InvocableVariable(label='Matter Record Id' required=true)
    global Id matter_id;
    @InvocableVariable(label='Old Matter Record Id' required=false)
    global String old_matter_id;
    @InvocableVariable(label='Record Id' required=true)
    global Id record_id;
    global InputParam() {

    }
}
}
