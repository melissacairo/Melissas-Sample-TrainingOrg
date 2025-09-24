/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class ResolutionSplitService {
    global ResolutionSplitService() {

    }
    @InvocableMethod(label='Create Resolution Splits' description='Counts the number of Referral Percentage on each Role object of type Referral Source and creates a new Resolution Split record for each Referral Source with a percentage greater than 0.')
    global static void createResolutionSplits(List<litify_pm.ResolutionSplitService.ResolutionWrapper> resolutionWrapper) {

    }
global class ResolutionWrapper {
    @InvocableVariable(label='Delete Existing Resolution Splits' description='Will delete existing resolution splits if true. If set to false will error if existing splits are found' required=false)
    global Boolean deleteExistingResolutionSplits;
    @InvocableVariable(label='Resolution' required=true)
    global litify_pm__Resolution__c resolution;
    global ResolutionWrapper() {

    }
}
}
