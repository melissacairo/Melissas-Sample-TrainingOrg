/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBSend {
    global PBSend() {

    }
    @InvocableMethod(label='Send' description='Send the given referral to another firm')
    global static void send(List<litify_pm.PBSend.ProcessBuilderSendWrapper> sendItems) {

    }
global class ProcessBuilderSendWrapper {
    @InvocableVariable( required=false)
    global String agreement_name;
    @InvocableVariable( required=false)
    global String agreement_type;
    @InvocableVariable( required=false)
    global Integer expiration_hours;
    @InvocableVariable( required=false)
    global Id handling_firm_id;
    @InvocableVariable( required=false)
    global Boolean is_anonymous;
    @InvocableVariable( required=false)
    global Id record_id;
    @InvocableVariable( required=false)
    global Decimal referral_fee;
    global ProcessBuilderSendWrapper() {

    }
}
}
