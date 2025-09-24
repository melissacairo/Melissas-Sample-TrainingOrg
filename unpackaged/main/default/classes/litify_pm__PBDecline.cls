/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBDecline {
    global PBDecline() {

    }
    @InvocableMethod(label='Decline' description='Declines the given referral')
    global static void decline(List<litify_pm.PBDecline.ProcessBuilderDeclineWrapper> declineItems) {

    }
global class ProcessBuilderDeclineWrapper {
    @InvocableVariable( required=false)
    global String reason;
    @InvocableVariable( required=false)
    global Id record_id;
    global ProcessBuilderDeclineWrapper() {

    }
}
}
