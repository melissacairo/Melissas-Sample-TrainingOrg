/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBSendAgain {
    global PBSendAgain() {

    }
    @InvocableMethod(label='Send Again' description='Send the given referral to another firm again')
    global static void sendAgain(List<litify_pm.PBSendAgain.ProcessBuilderSendAgainWrapper> sendItems) {

    }
global class ProcessBuilderSendAgainWrapper {
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
    global ProcessBuilderSendAgainWrapper() {

    }
}
}
