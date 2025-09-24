/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBOpenMatter {
    global PBOpenMatter() {

    }
    @InvocableMethod(label='Open Matter' description='Converts the given intake to a matter')
    global static void openMatters(List<litify_pm.PBOpenMatter.ProcessBuilderOpenMatterWrapper> openMatterItems) {

    }
global class ProcessBuilderOpenMatterWrapper {
    @InvocableVariable( required=false)
    global Id case_type;
    @InvocableVariable( required=false)
    global Id matter_owner;
    @InvocableVariable( required=false)
    global Id matter_plan;
    @InvocableVariable( required=false)
    global Id matterTeamId;
    @InvocableVariable( required=false)
    global Boolean override_matter_plan;
    @InvocableVariable( required=false)
    global Id record_id;
    global ProcessBuilderOpenMatterWrapper() {

    }
}
}
