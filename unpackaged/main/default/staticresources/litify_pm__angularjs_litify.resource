var app = angular.module('litify', ['localytics.directives', 'angucomplete-alt']);

app.directive('lightningIcon', [function() {
	return {
		restrict: 'E',
		templateUrl: window.litify.templateBaseDirectory + '/lightning_icon.html',
		scope: {
			package: '<',
			icon: '<',
			size: '<',
			iconType: '<',
			position: '<',
			color: '<'
		},
		link: function(scope) {
			scope.lightningAssetsBasePath = window.litify.lightningAssetsBasePath;

			var iconClasses = [];
			var baseClass = '';
			if (scope.iconType) {
				baseClass = 'slds-' + scope.iconType + '__icon';
			} else {
				baseClass = 'slds-icon';
			}
			iconClasses.push(baseClass);

			if (scope.size) {
				iconClasses.push(baseClass + '--' + scope.size);
			}

			if (scope.position) {
				iconClasses.push(baseClass + '--' + scope.position);
			}

			if (scope.color) {
				iconClasses.push('slds-icon-text-' + scope.color);
			}

			scope.iconClasses = iconClasses;
		}
	};
}]);
app.directive('lightningAlertDialog', [function() {
	return {
		restrict: 'E',
		templateUrl: window.litify.templateBaseDirectory + '/lightning_alert_dialog.html',
		scope: {
			opts: '<',
			top: '<'
		},
		link: function($scope, element) {
			$scope.height = element.height();
			$scope.lightningBasePath =  window.litify.lightningAssetsBasePath;
		}
	};
}]);

app.directive('lightningModal', [function() {
	return {
		restrict: 'E',
		transclude: true,
		templateUrl: window.litify.templateBaseDirectory + '/lightning_modal.html',
		scope: {
			show: '=',
			header: '<',
			save: '&',
			saveText: '<',
			showSave: '<',
			cancelText: '<',
			context: '<',
			showFooter: '<',
			top: '<',
			fullHeight: '<'
		},
		link: function(scope, element) {
			if (typeof scope.showSave == 'undefined') {
				scope.showSave = true;
			}
			scope.lightningBasePath =  window.litify.lightningAssetsBasePath;
			scope.saveText = scope.saveText || 'Save';
			scope.cancelText = scope.cancelText || 'Cancel';

			scope.doSave = function() {
				var fnSave = scope.save();
				if (fnSave) {
					fnSave(scope.context);
				}
			};
		}
	};
}]);

app.factory('objectConverter', function() {
  return {
    objectPropertiesToSelect: function(allObjectProperties) {
      return _.map(allObjectProperties, function(o) {
        var fieldName;
        var fieldLabel;
        if (o.relationship_name) {
          fieldLabel = '[' + o.relationship_name + '].' + o.field_label;
          fieldName = o.relationship_name + '.' + o.field_name;
        } else {
          fieldLabel = '[' + o.object_name + '].' + o.field_label;
          fieldName = o.field_name;
        }

        var fieldType;
        switch(o.field_type.toLowerCase()) {
          case 'picklist':
          fieldType = 'select';
          break;
          case 'multipicklist':
          fieldType = 'multiselect';
          break;
          case 'double':
          fieldType = 'decimal';
          break;
          default:
          fieldType = o.field_type.toLowerCase();
          break;
        }

        var fieldOptions = _.map(o.field_options, function(o) { return { label: o, value: o }; });

        var object_name = 'litify_pm__Intake__c';
        return {
          label: fieldLabel,
          object_name: object_name,
          field_name: fieldName,
          value: '!FIELD_VALUE(' + fieldName + ')',
          type: fieldType,
          options: fieldOptions,
          referenced_object_name: o.referenced_object_name,
          reference_lookup_label: ''
        };
      });
    }
  };
});

app.factory('inputHandler', function() {
	return {
		onReferenceChange: function(operator, refId, refName) {
			var ret;
			if (operator === 'contains' || operator === 'not_contains') {
				ret = refName;
			} else {
				ret = refId;
			}
			return ret;
		},
		validateValue: function(value) {
			var type = typeof value;
			switch (type) {
				case 'string':
				    return value.length;
				case 'number':
				    return value;
				case 'boolean':
				    return (type === 'boolean');
				case 'object':
				    return Array.isArray(value) ? value.length : value;
				default: return value;
		    }
		},
	}
});

app.directive('inputAssociatedMultipleValue', ['$q', '$timeout', 'inputHandler', function($q, $timeout, inputHandler) {
	return {
		restrict: 'E',
		scope: {
			ngModel: '=',
			valueMultiple: '=',
			formula: '=',
			referencedObjectName: '<',
			referencedObjectId: '<',
			inputType: '<',
			options: '<',
			ngChange: '<',
			lookupLabel: '=',
			operator: '=',
		},
		templateUrl: 'inputAssociatedMultipleValue.html',
		link: function($scope) {

			// set ngModel to empty value when Field input is deselected
			$scope.$on('DESELECT_FIELD_EVENT', function(event) {
				var scope = event.currentScope;
				scope.ngModel = null;
			});

			$scope.$on('addCriteriaRowEvent', function(event) {
			    var scope = event.currentScope;
			    if (scope.input && !scope.multipleValue2.includes(scope.input)) {
			        scope.addValue();
			    }
			});

			if ($scope.referencedObjectName) {
				$scope.$watch('operator', function(oldValue, newValue) {
					if (oldValue !== newValue) {
						$scope.ngModel = inputHandler.onReferenceChange($scope.operator, $scope.referencedObjectId, $scope.lookupLabel);
					}
				}, true);
			}

			function convertToArray(){
				if (Array.isArray($scope.ngModel) ) {
						$scope.multipleValue2 = $scope.ngModel;
				} else {
					$scope.multipleValue2 = [];
					if ($scope.ngModel) {
						$scope.multipleValue2.push($scope.ngModel);
					}
				}
				// clone
				$scope.ngModel = $scope.multipleValue2.slice(0);
				// add a new row but not added to ngModel
				if($scope.multipleValue2.length == 0) {
					$scope.multipleValue2.push('');
				}

			}
			convertToArray();


			$scope.updateValueFromMultipleValues = function(){
				var theNewArray = [];
				var lastValueIsEmpty = false;

				for( var index = 0 ; index < $scope.multipleValue2.length ; index++ ) {
					var value = $scope.multipleValue2[index];

					//if value is not empty
					if(value && ( typeof value == 'number' || value.trim() ) ) {
						theNewArray.push(value);
					}
					// if there is no value but is the lastone on the array we show this emtpy row but this is not added to ngModel
					else if (index == $scope.multipleValue2.length -1) {
						lastValueIsEmpty = true;
					}
				}

				$scope.ngModel = theNewArray.slice(0);

				if (lastValueIsEmpty) {
					theNewArray.push('');
				}
				$scope.multipleValue2 = theNewArray;

			}

			$scope.addValue = function(){
				$scope.multipleValue2.push('');
				$scope.updateValueFromMultipleValues();
			}

			$scope.deleteAValue = function(valueToDelete) {
				$scope.multipleValue2 = _.reject($scope.multipleValue2, function(value) {
					return value === valueToDelete;
				});
				$scope.updateValueFromMultipleValues();
			}

		}
	};
}]);

app.directive('inputAssociatedValue', ['$q', '$timeout', 'inputHandler', function($q, $timeout, inputHandler) {
	return {
		restrict: 'E',
		scope: {
			ngModel: '=',
			valueMultiple: '=',
			formula: '=',
			referencedObjectName: '<',
			referencedObjectId: '<',
			lookupLabel: '<',
			inputType: '<',
			options: '<',
			ngChange: '<',
			lookupLabel: '=',
			operator: '=',
			disbleFormulas: '=',
			dateValue: '='
		},
		templateUrl: 'inputAssociatedValue.html',
		link: function($scope) {
			if ($scope.lookupLabel && !$scope.initialValue) {
				$scope.initialValue = $scope.lookupLabel;
			}
			// set ngModel to empty value when Field input is deselected
			// this is so the next field of the same row won't have the previous value
			$scope.$on('DESELECT_FIELD_EVENT', function(event) {
				var scope = event.currentScope;
				scope.ngModel = null;
			});

			function changeLabelFromId(){
				if ($scope.ngModel && $scope.referencedObjectName) {
					if ($scope.operator === 'contains' || $scope.operator === 'not_contains') {
						$scope.initialValue = $scope.ngModel;
					} else {
						// for init
						$scope.referencedObjectId = $scope.referencedObjectId || $scope.ngModel;
						sforce.connection.query("SELECT name FROM " + $scope.referencedObjectName + " WHERE ID = '" + $scope.referencedObjectId + "'", {
							onSuccess: function(result) {
								$scope.initialValue = result.records.Name;
							},
							onFailure: function(err) {
								console.log(err);
							}
						});
					}
				}
			}
			changeLabelFromId();

			// This is necessary since sometimes this directive load without referencedObjectName and this causes the label not to load
			$scope.$watch('referencedObjectName', function () {
				changeLabelFromId();
			}, true);

			// For reference types, with contains or not contains operators
			// we want to pass back their text value for wildcard comparison queries
			// this is for toggling between their Id and Text value
			if ($scope.referencedObjectName) {
				$scope.$watch('operator', function(oldValue, newValue) {
					if (oldValue !== newValue) {
						$scope.ngModel = inputHandler.onReferenceChange($scope.operator, $scope.referencedObjectId, $scope.lookupLabel);
					}
				}, true);
			}


			function deleteMultipleValues(){
				if (Array.isArray($scope.ngModel) ) {
						$scope.ngModel = '';
					}

			}
			deleteMultipleValues();

			$scope.booleanOptions = [
			    { label: 'True', value: 'true' },
			    { label: 'False', value: 'false' }
			];

			$scope.formulaOptions = [
				{ label: 'days ago', value: 'daysago' },
				{ label: 'months ago', value: 'monthsago' },
				{ label: 'years ago', value: 'yearsago' },
				{ label: 'hours ago', value: 'hoursago' },
				{ label: 'minutes ago', value: 'minutesago' },
			];


			$scope.booleanOptions = [
				{ label: 'true', value: 'true' },
				{ label: 'false', value: 'false' }
			];


			$scope.formatDate = function() {
				//2011-01-10 salesforce date format
				//2011-01-10 00:00:00 salesforce date time format
				if( !isNaN($scope.dateValue.getTime() ) ) {
					let myDate = new Date($scope.dateValue);

					var month = myDate.getMonth() + 1;
					if (month < 10) {
						month = '0' + month;
					}

					var day = myDate.getDate();
					if (day < 10) {
						day = '0' + day;
					}

					var myDateString = myDate.getFullYear() + '-' + month + '-' + day

					if ($scope.inputType == 'datetime') {
						var hours = myDate.getHours();
						if (hours < 10) {
							hours = '0' + hours;
						}

						var minutes = myDate.getMinutes();
						if (minutes < 10) {
							minutes = '0' + minutes;
						}

						var seconds = myDate.getMilliseconds();
						if (seconds < 10) {
							seconds = '0' + seconds;
						}

						myDateString = myDateString + ' ' + hours + ':' + minutes + ':' + seconds;
					}
					$scope.ngModel = myDateString;

				} else {
					$scope.ngModel = '';
				}
			}

			$scope.searchReferences = function(userInputString, timeoutPromise) {
				var deferred = $q.defer();

				var callbacks = {
					onSuccess: function(result) {
						var records = result.getArray('searchRecords');
						var mapped = _.map(records, function(r) {
							r = r.record;
							return {
								name: r.Name,
								id: r.Id
							};
						});
						deferred.resolve(mapped);
					},
					onFailure: function(err) {
						deferred.reject(err);
					}
				};

				var result = sforce.connection.search("find {*" + userInputString + '*} IN Name Fields RETURNING ' + $scope.referencedObjectName + '(id, name)', callbacks);

				return deferred.promise;
			};

      $scope.setSelectedReference = function(selected, s2) {
        if (selected) {
          $scope.referencedObjectId = selected.originalObject.id;
          $scope.lookupLabel = selected.originalObject.name;
          $scope.ngModel = inputHandler.onReferenceChange($scope.operator, $scope.referencedObjectId, $scope.lookupLabel);
		}
		else {
			$scope.ngModel = null;
			$scope.lookupLabel = '';
			$scope.referencedObjectId = '';
		}
      };
    }
  };
}]);

app.directive('selectOperator', function() {
	return {
		restrict: 'E',
		scope: {
			inputType: '<',
			ngModel: '=',
			ngChange: '<'
		},
		templateUrl: 'selectOperator.html',
		link: function($scope) {
			$scope.operatorOptions = [
				{ label: 'equals', value: 'equals', applies_to: ['string', 'integer', 'decimal', 'select', 'multiselect', 'date', 'datetime', 'email', 'phone', 'percent', 'textarea', 'url', 'currency', 'text_encrypted', 'reference'] },
				{ label: 'less than', value: 'less_than', applies_to: ['integer', 'decimal', 'percent', 'currency'] },
				{ label: 'less than or equals', value: 'less_than_or_equals', applies_to: ['integer', 'decimal', 'percent', 'currency'] },
				{ label: 'greater than', value: 'greater_than', applies_to: ['integer', 'decimal', 'percent', 'currency'] },
				{ label: 'greater than or equals', value: 'greater_than_or_equals', applies_to: ['integer', 'decimal', 'percent', 'currency'] },
				{ label: 'not equals', value: 'not_equals', applies_to: ['string', 'integer', 'decimal', 'select', 'multiselect', 'date', 'datetime', 'email', 'phone', 'percent', 'textarea', 'url', 'currency', 'text_encrypted', 'reference'] },
				{ label: 'contains', value: 'contains', applies_to: ['string', 'select', 'multiselect', 'email', 'phone', 'textarea', 'url', 'text_encrypted'] },
				{ label: 'not contains', value: 'not_contains', applies_to: ['string', 'select', 'multiselect', 'email', 'phone', 'textarea', 'url', 'text_encrypted'] },
				{ label: 'is contained in', value: 'is_contained_in', applies_to: ['string', 'select', 'multiselect', 'email', 'phone', 'textarea', 'url', 'text_encrypted'] },
				{ label: 'is not contained in', value: 'is_not_contained_in', applies_to: ['string', 'select', 'multiselect', 'email', 'phone', 'textarea', 'url', 'text_encrypted'] },
				{ label: 'earlier than', value: 'earlier_than', applies_to: ['date', 'datetime'] },
				{ label: 'earlier than or equals', value: 'earlier_than_or_equals', applies_to: ['date', 'datetime'] },
				{ label: 'later than', value: 'later_than', applies_to: ['date', 'datetime'] },
				{ label: 'later than or equals', value: 'later_than_or_equals', applies_to: ['date', 'datetime'] },
				{ label: 'is true', value: 'is_true', applies_to: ['boolean'] },
				{ label: 'is false', value: 'is_false', applies_to: ['boolean'] }
			];

			$scope.operatorAppliesToType = function(operator) {
				return _.contains(operator.applies_to, ($scope.inputType || '').toLowerCase());
			};
		}
	};
});

app.directive('selectObjectProperty', ['objectConverter', function(objectConverter) {
	return {
		restrict: 'E',
		scope: {
			ngModel: '=',
			selectTitle: '=',
			objectPropertiesSelector: '<',
			selectedObjectProperty: '='
		},
		templateUrl: 'selectObjectProperty.html',
		link: function($scope) {
			var objectProperties = JSON.parse(jQuery($scope.objectPropertiesSelector).val());
			$scope.objectPropertyOptions = objectConverter.objectPropertiesToSelect(objectProperties);
			$scope.onPropertySelected = function() {
				var selectedObjectProperty = _.find($scope.objectPropertyOptions, function(opt) {
					return opt.field_name == $scope.ngModel;
				});

				// emit event to remove model value from other directives when deselecting field
				if (typeof $scope.selectedObjectProperty === 'object' && !_.isEqual($scope.selectedObjectProperty, selectedObjectProperty)) {
					$scope.$parent.$broadcast('DESELECT_FIELD_EVENT');
				}

				$scope.selectedObjectProperty = selectedObjectProperty;
			};
			$scope.onPropertySelected();
		}
	};
}]);

app.directive('selectQuestionOrProperty', ['objectConverter', function(objectConverter) {
  return {
    restrict: 'E',
    scope: {
      ngModel: '=',
      questionsSelector: '<',
      objectPropertiesSelector: '<',
      ngChange: '<'
    },
    templateUrl: 'selectQuestionOrProperty.html',
    link: function($scope) {

      var objectProperties = JSON.parse(jQuery($scope.objectPropertiesSelector).val());
      var allQuestions = JSON.parse(jQuery($scope.questionsSelector).val());

      $scope.objectPropertyOptions = objectConverter.objectPropertiesToSelect(objectProperties);

      var allQuestionOptions = _.map(allQuestions, function(o) {
        var options;
        try {
          options = JSON.parse(o.AnswerOptions || '[]');
        } catch (e) {
          options = [];
        }
        options = _.map(options, function(o) { return { label: o, value: o }; });

        var questionType;
        switch(o.AnswerType.toLowerCase()) {
          case 'lookup':
          questionType = 'reference';
          break;
          default:
          questionType = o.AnswerType.toLowerCase();
          break;
        }

        return {
          hash: o.Id,
          label: o.Label,
          value: '!QUESTION_ID(' + o.Id + ')',
          type: questionType ? questionType : '',
          options: options
        };
      });

      $scope.valueOptions = $scope.objectPropertyOptions.concat(allQuestionOptions);
    }
  };
}]);

