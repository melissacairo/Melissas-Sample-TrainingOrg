/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class CreateTaskSetFromProcess {
    global CreateTaskSetFromProcess() {

    }
    @InvocableMethod(label='Assign Task set for matter')
    global static void createTasks(List<litify_ext.CreateTaskSetFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='Task Set Id' required=true)
    global Id default_task_set_Id;
    @InvocableVariable(label='Related Matter Id to Assign Task.' required=true)
    global Id matter_id;
    global InputParam() {

    }
}
}
