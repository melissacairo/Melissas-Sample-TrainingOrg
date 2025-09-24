/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class MatterPlanSwitchFromProcess {
    global MatterPlanSwitchFromProcess() {

    }
    @InvocableMethod(label='Switch Matter Plan (Extension)')
    global static void switchMatterPlan(List<litify_ext.MatterPlanSwitchFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='Close Default Matter Tasks?' required=true)
    global Boolean isCloseTasks;
    @InvocableVariable(label='Delete Tasks' description='define if tasks Need to be deleted' required=false)
    global Boolean isDeleteTasks;
    @InvocableVariable(label='Override Matter plan' description='It will delete matter plan & stages from current matter and set new Matter Plan' required=false)
    global Boolean isOverrideMatterPlan;
    @InvocableVariable(label='Matter Id' required=true)
    global Id matter_id;
    @InvocableVariable(label='Matter Plan Id' required=false)
    global Id matter_plan_id;
    @InvocableVariable(label='(Depricated)' required=false)
    global Id matter_plan_name;
    @InvocableVariable(label='Matter Team Id' description='Optional, Will add new matter team members if needed' required=false)
    global Id matterTeamId;
    @InvocableVariable(label='Matter Plan Name' required=false)
    global String plan_name;
    @InvocableVariable(label='Stage Name' description='Optional, Define active stage fro matter plan switch' required=false)
    global String stageName;
    @InvocableVariable(label='Task Status' description='This Status  will override default task status for old stage. Default value N/A' required=false)
    global String taskStatus;
    global InputParam() {

    }
}
}
