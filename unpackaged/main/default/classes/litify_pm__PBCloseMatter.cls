/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBCloseMatter {
    global PBCloseMatter() {

    }
    @InvocableMethod(label='Close Matter' description='Closes the matters with the given record_id')
    global static void closeMatters(List<litify_pm.PBCloseMatter.ProcessBuilderCloseMatterWrapper> closeMatterItems) {

    }
global class ProcessBuilderCloseMatterWrapper {
    @InvocableVariable( required=false)
    global Decimal amount;
    @InvocableVariable( required=false)
    global String close_reason;
    @InvocableVariable( required=false)
    global String close_reason_sub_status;
    @InvocableVariable( required=false)
    global String reason;
    @InvocableVariable( required=false)
    global Id record_id;
    @InvocableVariable( required=false)
    global String turn_down_reason;
    @InvocableVariable( required=false)
    global String turn_down_reason_other;
    global ProcessBuilderCloseMatterWrapper() {

    }
}
}
