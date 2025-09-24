/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class SwitchStageFromProcess {
    global SwitchStageFromProcess() {

    }
    @InvocableMethod(label='Switch Stage On Matter')
    global static void SwitchStageFromProcessAction(List<litify_ext.SwitchStageFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable( required=false)
    global String closeTaskStatus;
    @InvocableVariable( required=true)
    global Boolean isCloseTasks;
    @InvocableVariable( required=true)
    global Id matter_id;
    @InvocableVariable( required=true)
    global String stageName;
    global InputParam() {

    }
}
}
