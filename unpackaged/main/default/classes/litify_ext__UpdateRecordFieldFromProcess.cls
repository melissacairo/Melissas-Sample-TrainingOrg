/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class UpdateRecordFieldFromProcess {
    global UpdateRecordFieldFromProcess() {

    }
    @InvocableMethod(label='Update Record field')
    global static void updateRecordField(List<litify_ext.UpdateRecordFieldFromProcess.InputParam> l_inputParams) {

    }
global class InputParam {
    @InvocableVariable(label='Boolean Value' required=false)
    global Boolean boolean_value;
    @InvocableVariable(label='Date Value' required=false)
    global Date date_value;
    @InvocableVariable(label='Date time Value' required=false)
    global Datetime datetime_value;
    @InvocableVariable(label='Number Value' required=false)
    global Decimal number_value;
    @InvocableVariable(label='Field Label or Api Name which need to be updated' required=true)
    global String recordField;
    @InvocableVariable(label='Related Record Id ' required=true)
    global Id recordId;
    @InvocableVariable(label='String Value' required=false)
    global String str_value;
    global InputParam() {

    }
}
}
