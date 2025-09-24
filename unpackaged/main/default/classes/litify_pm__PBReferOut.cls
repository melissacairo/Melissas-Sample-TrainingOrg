/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBReferOut {
    global PBReferOut() {

    }
    @InvocableMethod(label='Refer Out' description='refer the given matter or intake to another firm')
    global static void referOut(List<litify_pm.PBReferOut.ProcessBuilderReferOutWrapper> ReferOutItems) {

    }
global class ProcessBuilderReferOutWrapper {
    @InvocableVariable( required=false)
    global String agreement_name;
    @InvocableVariable( required=false)
    global String agreement_type;
    @InvocableVariable( required=false)
    global Account client;
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
    @InvocableVariable( required=false)
    global String sobject_name;
    global ProcessBuilderReferOutWrapper() {

    }
}
}
