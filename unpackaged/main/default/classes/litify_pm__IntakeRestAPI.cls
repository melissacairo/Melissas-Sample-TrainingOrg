/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
@RestResource(urlMapping='/api/v1/intake/create')
global class IntakeRestAPI {
    global IntakeRestAPI() {

    }
    @HttpPost
    global static litify_pm.IntakeRestAPI.IntakeResponse doPost() {
        return null;
    }
global class IntakeResponse {
    global String accountId;
    global String intakeId;
    global Boolean isSuccess;
    global String logId;
    global String message;
    global IntakeResponse() {

    }
}
}
