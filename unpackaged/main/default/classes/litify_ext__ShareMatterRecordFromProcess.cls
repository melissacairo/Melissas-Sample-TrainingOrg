/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class ShareMatterRecordFromProcess {
    global ShareMatterRecordFromProcess() {

    }
    @InvocableMethod(label='Extension - Share Matter Record With Team Members')
    global static void shareMatterRecord(List<litify_ext.ShareMatterRecordFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='AccessLevel ("Edit". "Read")' required=false)
    global String accessLevel;
    @InvocableVariable(label='Define if record should be private or not' required=true)
    global Boolean isPrivate;
    @InvocableVariable(label='Matter Record Id' required=true)
    global Id matter_id;
    global Set<Id> s_new_members;
    global Set<Id> s_old_members;
    global InputParam() {

    }
}
}
