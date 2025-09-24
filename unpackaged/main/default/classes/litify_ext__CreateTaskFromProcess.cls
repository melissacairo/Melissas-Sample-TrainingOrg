/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class CreateTaskFromProcess {
    global CreateTaskFromProcess() {

    }
    @InvocableMethod(label='Create Default Matter Task')
    global static void createTasks(List<litify_ext.CreateTaskFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='Default matter Task Id' required=true)
    global Id default_task_Id;
    @InvocableVariable(label='Optional. Pass dynamic interval' required=false)
    global Decimal due_date_interval;
    @InvocableVariable(label='Update Task if Task exist and not completed' required=false)
    global Boolean isUpdate;
    @InvocableVariable(label='Related Matter Id to Assign Task.' required=true)
    global Id matter_id;
    @InvocableVariable(label='Optional. Override owner id' required=false)
    global Id owner_id;
    @InvocableVariable(label='Optional. Start Date for Due date calcualtion' required=false)
    global Date start_date;
    @InvocableVariable(label='Optional. Override subject if needed' required=false)
    global String subject;
    global InputParam() {

    }
}
}
