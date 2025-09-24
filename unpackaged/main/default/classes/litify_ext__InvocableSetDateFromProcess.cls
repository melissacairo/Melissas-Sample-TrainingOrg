/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class InvocableSetDateFromProcess {
    global InvocableSetDateFromProcess() {

    }
    @InvocableMethod(label='Set Dates from Process')
    global static List<Date> setDueDate(List<litify_ext.InvocableSetDateFromProcess.InputParam> l_inputParams) {
        return null;
    }
global class InputParam {
    @InvocableVariable(label='Date Value' required=true)
    global Date DateValue;
    @InvocableVariable(label='Number Of Days' required=true)
    global Integer NumberOfDays;
    @InvocableVariable(label='Option param : Days After, Days Before, Business Days After,Business Days Before' required=true)
    global String Option;
    global InputParam() {

    }
}
}
