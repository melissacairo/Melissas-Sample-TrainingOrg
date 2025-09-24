/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class CreateRoleFromProcess {
    global CreateRoleFromProcess() {

    }
    @InvocableMethod(label='Create/Update Role From (Extensions)')
    global static void roleAction(List<litify_ext.CreateRoleFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='Party Field Api Name' required=false)
    global String apiFieldName;
    @InvocableVariable(label='Matter Or Intake Id' required=true)
    global Id matterIntakeId;
    @InvocableVariable(label='Party new Id' required=true)
    global Id newValueId;
    @InvocableVariable(label='Party old Id' required=false)
    global String previousValueId;
    @InvocableVariable(label='Record Id to which value changed' required=true)
    global Id recordId;
    @InvocableVariable(label='Role Category' required=false)
    global String role_category;
    @InvocableVariable(label='Role Sub-Category' required=false)
    global String role_sub_category;
    @InvocableVariable(label='Role Field Api Name' required=false)
    global String roleApiFieldName;
    global InputParam() {

    }
}
}
