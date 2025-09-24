var cqcApp = angular.module('cqcApp', ['localytics.directives', 'litify']);

cqcApp.controller('cqcController', ['$scope', 'inputHandler', function($scope, inputHandler) {
  $scope.newRow = { value_1: null, operator: null, value_2: '', multi_select_options: [], formula: null, lookup_label: '' };
  $scope.newMappingRow = { field_obj: {}, value_obj: '', multi_select_options: [], date_value: null };
  $scope.criteriaError = false;

  $scope.strCriteria = jQuery("textarea[id$=':criteria']").val();
  try { 
    $scope.criteria = JSON.parse($scope.strCriteria); 
  } catch(err) {
    $scope.criteria = [];
  }
  $scope.strModifications = jQuery("textarea[id$=':modifications']").val();
  try { 
    $scope.modifications = JSON.parse($scope.strModifications); 
  } catch(err) {
    $scope.modifications = [];
  }

  $scope.remove = function(crit) {
    var criteria = _.reject($scope.criteria, function(c) { return c == crit; });
    $scope.criteria = criteria;
    refreshCriteria();
  };

  $scope.removeMapping = function(map) {
    var modifications = _.reject($scope.modifications, function(m) { return m == map; });
    $scope.modifications = modifications;
    refreshModifications();
  };

$scope.$watch(function(scope) { return scope.strCriteria; }, function(newValue) {
    try { 
      $scope.criteria = JSON.parse(newValue);
    } catch (err) { console.log(err, newValue); }
  });


  // watch value_1 and update select lists accordingly
  $scope.$watch(function(scope) { return scope.newRow.value_1; }, function(newValue) {
      if($scope.newRow.value_1 != null) { 
        if ($scope.newRow.value_1.type == 'reference' && $scope.newRow.value_1.hash && !$scope.newRow.value_1.referenced_object_name) {
          // lookup the referenced object type
          sforce.connection.query("SELECT litify_pm__Lookup_Sobject_Type__c FROM litify_pm__Question__c WHERE ID = '" + $scope.newRow.value_1.hash + "'", {
            onSuccess: function(result) {
              $scope.newRow.value_1.referenced_object_name = result.records["litify_pm__Lookup_Sobject_Type__c"];
            },
            onFailure: function(err) {
              console.log(err);
            }
          });
        } 
      }      

      $scope.newRow.value_2 = '';
      $scope.newRow.multi_select_options = [];
      $scope.newRow.formula = null;
  });

  var refreshCriteria = function() {
    $scope.strCriteria = angular.toJson($scope.criteria);
  };
  var refreshModifications = function() {
    $scope.strModifications = angular.toJson($scope.modifications);
  };

  $scope.canUseOR = function(inputType, operator){    
    if (operator && inputType) {
      return _.contains(['equals', 'not_equals'], operator.toLowerCase()) && 
        _.contains(['string', 'textarea', 'email', 'phone', 'decimal', 'integer', 'url', 'currency', 'percent'], inputType.toLowerCase());
    } else return false;
  }

  $scope.addCriteriaRow = function() {
    $scope.$broadcast('addCriteriaRowEvent');

    var newRow = $scope.newRow;
    var isValue2Valid = inputHandler.validateValue(newRow.value_2);
    $scope.criteriaError = false;

    // do not save if the criteria have an empty value
    if( !(newRow.value_1 && newRow.operator && ( isValue2Valid || (newRow.multi_select_options && newRow.multi_select_options.length) || (newRow.value_1.type == 'boolean')) ) ){
      var criteriaErrorMessage = 'Criterion Not Valid: Something is Missing';      
      if (!newRow.value_1) {
        criteriaErrorMessage = 'Criterion Not Valid: Please Select a Question or Field';
      } else if (!newRow.operator) {
        criteriaErrorMessage = 'Criterion Not Valid: Please Select an Operator';
      } else if (!(newRow.multi_select_options && newRow.multi_select_options.length ) && (newRow.value_1.type.toLowerCase().includes('select') || newRow.value_1.type == 'reference') ){
        criteriaErrorMessage = 'Criterion Not Valid: Please Select an Option From the Drop Down';
      } else if (!isValue2Valid) {
        criteriaErrorMessage = 'Criterion Not Valid: Please Select a Value';
      }

      $scope.criteriaErrorMessage = criteriaErrorMessage;
      $scope.criteriaError = true;
      return;
    }

    var value_2_array;
    //if not array create one
    if (!Array.isArray(newRow.value_2) ) {
      value_2_array = [];
      //if there is value put it on the array
      if(newRow.value_2) {
        value_2_array.push(newRow.value_2);
      }     
    } else {
      value_2_array = newRow.value_2;
    }

    if (newRow.value_1.type === 'multiselect') {
      value_2_array = [];
      multiSelectValue2 = _.reduce(newRow.multi_select_options, function(memo, str) {
      return memo + ';' + str; 
      });
      value_2_array.push(multiSelectValue2);
    }

    var value_2_label = '';
    var value_2_typed = [];

    var isFirst = true;
    _.each(value_2_array, function(value2) {

      var joiner = newRow.operator == 'equals' ? '(Or)' : '(And)';
      var formulaName = newRow.value_1.type;
      var labelforEachValue = isFirst ? '' : ' ' + joiner;
      labelforEachValue = labelforEachValue + ' ' + value2;

      // for formulas
      if (newRow.formula) {
        if (isNaN(value2)) {
          $scope.criteriaError = true;
          $scope.criteriaErrorMessage = "Criterion not valid: second parameter is not a number";
        }

        formulaName = newRow.formula.value;
        if (value2 == '1') {
          var formulaLabel = newRow.formula.label;
          formulaLabel = formulaLabel.replace('hours', 'hour');
          formulaLabel = formulaLabel.replace('days', 'day');
          formulaLabel = formulaLabel.replace('months', 'month');
          formulaLabel = formulaLabel.replace('years', 'year');
          labelforEachValue = value2 + ' ' + formulaLabel;
        }
        else {
          labelforEachValue = value2 + ' ' + newRow.formula.label;
        }
      }

      if ((newRow.value_1.type == 'date' || newRow.value_1.type == 'datetime') && !newRow.formula) {
        var validDate = new Date(value2);
        if (validDate == 'Invalid Date' || value2.indexOf("-") === -1 ) {
          $scope.criteriaError = true;
          $scope.criteriaErrorMessage = "Criterion not valid: date is not valid";
        }
      }

      // if lookup label is the name
      if (newRow.value_1.type == 'reference' && newRow.value_1.referenced_object_name) {
        labelforEachValue = newRow.lookup_label;
      } 

      value_2_label = value_2_label + labelforEachValue;

      value_2_typed.push('!' + formulaName.toUpperCase() + '(' + value2 + ')');

      isFirst = false;
    });

    if($scope.criteriaError) {
      return;
    }

    var crit = { value_1: newRow.value_1.value, value_1_label: newRow.value_1.label, operator: newRow.operator, value_2: value_2_typed, value_2_label: value_2_label };

    $scope.criteria.push(crit);

    $scope.newRow = { value_1: null, operator: null, value_2: null, multi_select_options: [], formula: null};

    refreshCriteria();
    
  };
  
  $scope.addModificationRow = function() {
    console.log($scope.newMappingRow);

    if ($scope.newMappingRow  && $scope.newMappingRow.field_obj && ($scope.newMappingRow.value_obj || ($scope.newMappingRow.multi_select_options && $scope.newMappingRow.multi_select_options.length ) ) ) {
      $scope.modifications = $scope.modifications || [];
      var field_name = $scope.newMappingRow.field_obj.field_name;
      var field_type = $scope.newMappingRow.field_obj.type;
      var value_obj = $scope.newMappingRow.value_obj;

      if (field_type === 'multiselect') {
        value_obj = _.reduce($scope.newMappingRow.multi_select_options, function(memo, str) {
          return memo + ';' + str; 
        });
      }

      if (field_type === 'reference') {
        label = $scope.newMappingRow.lookup_label;
      } else {
        label = value_obj;
      }
      
      var sobject_name = 'litify_pm__Intake__c';
      $scope.modifications.push(
                                {
                                  sobject_name: sobject_name,
                                  field_name: field_name,
                                  value: value_obj,
                                  field_type: field_type.toUpperCase(),
                                  formula: $scope.newMappingRow.formula,
                                  label: label
                                });

      $scope.newMappingRow = { field_obj: {}, value_obj: '', multi_select_options: [], date_value: null};

      refreshModifications();
    }
  };

}]);
