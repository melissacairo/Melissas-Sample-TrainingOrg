var diceApp = angular.module('diceApp', ['localytics.directives', 'litify']);

diceApp.controller('diceController', ['$scope', 'objectConverter', 'inputHandler', function($scope, objectConverter, inputHandler) {
  $scope.navigate_to_object = $("span#navigate_to_object").text();
  $scope.queries = angular.fromJson($("textarea[id$=':queries']").val() || '[]');

  $scope.ShowErrorMessage = false;
  $scope.errorList = [];

  $scope.sorting = angular.fromJson($("textarea[id$=':sorting']").val() || '[]');
  
  function ensureLength(arr, len) {
    arr = arr || [];
    for (var i = arr.length ; i < len ; i++) {
      arr.push({});
    }
  }
  

  $scope.operators_map = [
    { value: 'eq', label: 'Equals' },
    { value: 'not_eq', label: 'Does Not Equal' },
    { value: 'lt', label: 'Less/Earlier Than' },
    { value: 'lte', label: 'Less/Earlier Than or Equal' },
    { value: 'gt', label: 'Greater/Later Than' },
    { value: 'gte', label: 'Greater/Later Than or Equal' },
    { value: 'contains', label: 'Contains' },
    { value: 'not_contains', label: 'Does Not Contain' },
  ];

  $scope.formula_map = [
    { v1: 'hoursago', v2: 'hours_ago' },
    { v1: 'daysago', v2: 'days_ago' },
    { v1: 'monthsago', v2: 'months_ago' },
    { v1: 'yearsago', v2: 'years_ago' },
    { v1: 'minutesago', v2: 'minutes_ago' }
  ];
 
  // convert from standard formula to custom dice operator
  _.each($scope.queries, function(qry) {
    if (qry.diceFunction) {
      qry.diceFunction = _.find($scope.formula_map, function(op) {
        return op.v2 == qry.diceFunction;
      }).v1;

      qry.diceFunction = { value: qry.diceFunction };
    }
  });

  function ensureErrorsLength(arr, len) {
    arr = arr || [];
    for (var i = 0 ; i < len ; i++) {
      arr.push(false);
    }
  }  

  var queriesLength = 10;  
  ensureErrorsLength($scope.errorList, queriesLength);
  ensureLength($scope.queries, queriesLength);
  ensureLength($scope.sorting, 5);

  $scope.canUseOR = function(inputType, operator){    
    if (operator && inputType) {
      return _.contains(['eq', 'not_eq'], operator.toLowerCase()) && 
        _.contains(['string', 'textarea', 'email', 'phone', 'decimal', 'integer', 'url', 'currency', 'percent'], inputType.toLowerCase());
    } else return false;
  }

  $scope.availableOperators = function(field) {
    var operators = $scope.operators_map;
    if (field) {
      switch(field.type) {
        case 'boolean':
          return operators.filter(opr => opr.value === 'eq');
        case 'currency':
        case 'decimal':
        case 'percent':
        case 'integer':
        case 'date':
        case 'datetime':
          return operators.filter(opr => opr.value !== 'contains' && opr.value !== 'not_contains');
        case 'id':
        case 'reference':
        case 'url':
        case 'email':
        case 'phone':
        case 'address':
        case 'string':
        case 'select':
        case 'textarea':
        case 'encryptedstring':
          return operators.filter(opr => opr.value == 'eq' || opr.value === 'not_eq' || opr.value === 'contains' || opr.value === 'not_contains');
        default: return;
      }
    }
  }

  function validateBeforeSave() {
    $scope.ShowErrorMessage = false;
    var queries = $scope.queries;
    var isValid = true;


    for (var i = 0 ; i < queries.length ; i++) {
      var qVal = inputHandler.validateValue(queries[i].value);
      if(queries[i] && queries[i].fieldName && queries[i].operator && queries[i].operator.length &&
         ( (!queries[i].value || !qVal) && (!queries[i].multi_select_options || !queries[i].multi_select_options.length)) ) {
        $scope.errorList[i] = true;
        isValid = false;
        $scope.ShowErrorMessage = true;
      } else {
        $scope.errorList[i] = false;
      }
    }
    return isValid;
  }


  $scope.serializeBeforeSave = function() {
    if (validateBeforeSave()) {
      var queries = $scope.queries;
      queries = _.chain(queries)
        .each(function(qry) {
          delete qry.field;
          if (qry.diceFunction) {
            qry.diceFunction = qry.diceFunction.value;
            qry.diceFunction = _.find($scope.formula_map, function(op) {
              return op.v1 == qry.diceFunction;
            }).v2;
          }
        })
        .reject(function(qry) {
          return !qry.fieldName || 
            !qry.fieldName.length ||
            !qry.operator ||
            !qry.operator.length;
        })
        .value();
      $("textarea[id$=':queries']").val(angular.toJson(queries));

      var sorting = $scope.sorting;
      sorting = _.reject(sorting, function(srt) {
        return !srt.fieldName || !srt.fieldName.length || !srt.sorting || !srt.sorting.length;
      });
      $("textarea[id$=':sorting']").val(angular.toJson(sorting));

      // call the action that call the controller
      saveCQC();
    } else {      
      // scroll top to see the error message
      window.scrollTo(0,0);      
    }
    
  };

}]);